import Foundation
import Observation
import SwiftData
import SwiftUI
#if os(iOS)
    import UIKit
#endif

@MainActor
@Observable
final class TimerStore {
    var snapshot: TimerSnapshot = .initial
    var config: TimerConfig = .default
    var notificationAuthorizationState: NotificationAuthorizationState = .unknown
    var focusModeStatus: FocusModeStatus = .unknown
    var lastErrorMessage: String?
    var now: Date = .init()

    @ObservationIgnored var modelContext: ModelContext?
    @ObservationIgnored var preferences: UserTimerPreferences?
    @ObservationIgnored private let notificationService: any NotificationServicing
    @ObservationIgnored private let focusModeService: any FocusModeServicing
    @ObservationIgnored let watchConnectivityService: any WatchSyncServicing
    @ObservationIgnored let liveActivityService = LiveActivityService()
    #if os(iOS) || os(macOS)
        @ObservationIgnored private let ambientNoiseService: any AmbientNoiseServicing
    #endif
    @ObservationIgnored private var ticker: Timer?

    init() {
        self.notificationService = NotificationService()
        self.focusModeService = FocusModeService()
        self.watchConnectivityService = WatchConnectivityService()
        #if os(iOS) || os(macOS)
            self.ambientNoiseService = AmbientNoiseService()
        #endif
    }

    init(notificationService: any NotificationServicing) {
        self.notificationService = notificationService
        self.focusModeService = FocusModeService()
        self.watchConnectivityService = WatchConnectivityService()
        #if os(iOS) || os(macOS)
            self.ambientNoiseService = AmbientNoiseService()
        #endif
    }

    init(
        notificationService: any NotificationServicing,
        focusModeService: any FocusModeServicing
    ) {
        self.notificationService = notificationService
        self.focusModeService = focusModeService
        self.watchConnectivityService = WatchConnectivityService()
        #if os(iOS) || os(macOS)
            self.ambientNoiseService = AmbientNoiseService()
        #endif
    }

    init(
        notificationService: any NotificationServicing,
        focusModeService: any FocusModeServicing,
        watchConnectivityService: any WatchSyncServicing
    ) {
        self.notificationService = notificationService
        self.focusModeService = focusModeService
        self.watchConnectivityService = watchConnectivityService
        #if os(iOS) || os(macOS)
            self.ambientNoiseService = AmbientNoiseService()
        #endif
    }

    #if os(iOS) || os(macOS)
        init(
            notificationService: any NotificationServicing,
            focusModeService: any FocusModeServicing,
            ambientNoiseService: any AmbientNoiseServicing
        ) {
            self.notificationService = notificationService
            self.focusModeService = focusModeService
            self.watchConnectivityService = WatchConnectivityService()
            self.ambientNoiseService = ambientNoiseService
        }
    #endif

    deinit {
        self.ticker?.invalidate()
    }

    var sessionType: SessionType {
        self.snapshot.sessionType
    }

    var timerState: TimerState {
        self.snapshot.timerState
    }

    var boundaryStopPolicy: BoundaryStopPolicy {
        self.snapshot.boundaryStopPolicy
    }

    var remainingSeconds: Int {
        let fallback = TimerEngine.duration(for: self.snapshot.sessionType, config: self.config)
        return TimerEngine.remainingSeconds(
            timerState: self.snapshot.timerState,
            endDate: self.snapshot.endDate,
            pausedRemainingSec: self.snapshot.pausedRemainingSec,
            now: self.now,
            fallbackDurationSec: fallback
        )
    }

    var progress: Double {
        let duration = TimerEngine.duration(for: self.snapshot.sessionType, config: self.config)
        return TimerEngine.progress(durationSec: duration, remainingSec: self.remainingSeconds)
    }

    var formattedRemainingTime: String {
        let total = self.remainingSeconds
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    var completedFocusCount: Int {
        self.snapshot.completedFocusCount
    }

    var focusCycleStatusText: String {
        let frequency = max(1, self.config.longBreakFrequency)
        return "Cycle: \(self.snapshot.completedFocusCount % frequency)/\(frequency)"
    }

    var primaryActionTitle: String {
        switch self.snapshot.timerState {
        case .idle:
            "Start"
        case .running:
            "Pause"
        case .paused:
            "Resume"
        }
    }

    var canReset: Bool {
        self.snapshot.timerState != .idle || self.snapshot.startedAt != nil
    }

    var effectiveNotificationSoundEnabled: Bool {
        if self.config.respectFocusMode {
            return self.config.notificationSoundEnabled && !self.focusModeStatus.isFocused
        }
        return self.config.notificationSoundEnabled
    }
}

extension TimerStore {
    func bind(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.now = Date()
        self.startTickerIfNeeded()
        self.loadPreferencesIfNeeded()
        self.watchConnectivityService.activate()
        self.watchConnectivityService.setCommandHandler { [weak self] command in
            self?.handleWatchCommand(command)
        }
        self.refreshNotificationAuthorizationState()
        self.refreshFocusModeStatus()
        self.processElapsedSessionsIfNeeded()
        self.syncLiveActivity()
    }

    func handleScenePhaseChange(_ scenePhase: ScenePhase) {
        guard scenePhase == .active else {
            return
        }

        self.now = Date()
        self.refreshNotificationAuthorizationState()
        self.refreshFocusModeStatus()
        self.processElapsedSessionsIfNeeded()
        self.syncAmbientNoise()
    }

    func performPrimaryAction() {
        switch self.snapshot.timerState {
        case .idle:
            self.start()
        case .running:
            self.pause()
        case .paused:
            self.resume()
        }
    }

    func start() {
        let now = Date()
        self.now = now
        let duration = TimerEngine.duration(for: self.snapshot.sessionType, config: self.config)

        self.snapshot.startedAt = now
        self.snapshot.endDate = now.addingTimeInterval(TimeInterval(duration))
        self.snapshot.pausedRemainingSec = nil
        self.snapshot.timerState = .running

        self.requestNotificationPermissionAndScheduleIfNeeded()
        self.syncLiveActivity()
        self.syncAmbientNoise()

        #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    func pause() {
        guard self.snapshot.timerState == .running, let endDate = self.snapshot.endDate else {
            return
        }

        self.now = Date()
        self.snapshot.pausedRemainingSec = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        self.snapshot.endDate = nil
        self.snapshot.timerState = .paused
        self.notificationService.cancelSessionEndNotification()
        self.syncLiveActivity()
        self.syncAmbientNoise()

        #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    func resume() {
        guard self.snapshot.timerState == .paused else {
            return
        }

        let now = Date()
        self.now = now
        let fallback = TimerEngine.duration(for: self.snapshot.sessionType, config: self.config)
        let remaining = max(1, self.snapshot.pausedRemainingSec ?? fallback)

        self.snapshot.endDate = now.addingTimeInterval(TimeInterval(remaining))
        self.snapshot.timerState = .running
        self.snapshot.pausedRemainingSec = nil

        if self.snapshot.startedAt == nil {
            self.snapshot.startedAt = now
        }

        self.requestNotificationPermissionAndScheduleIfNeeded()
        self.syncLiveActivity()
        self.syncAmbientNoise()

        #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    func reset() {
        self.now = Date()
        self.snapshot.timerState = .idle
        self.snapshot.sessionType = .focus
        self.snapshot.startedAt = nil
        self.snapshot.endDate = nil
        self.snapshot.pausedRemainingSec = nil
        self.snapshot.completedFocusCount = 0
        self.notificationService.cancelSessionEndNotification()
        self.syncLiveActivity()
        self.syncAmbientNoise()
    }

    func skip() {
        self.now = Date()
        self.completeCurrentSession(at: Date(), dueToSkip: true)
        self.syncLiveActivity()
    }

    func setBoundaryStopPolicy(_ policy: BoundaryStopPolicy) {
        self.snapshot.boundaryStopPolicy = policy
        self.persistPreferences()
    }

    func updateFocusMinutes(_ minutes: Int) {
        self.config.setFocusMinutes(minutes)
        self.persistPreferences()
        self.handleConfigChangeWhileActiveTimer()
    }

    func updateShortBreakMinutes(_ minutes: Int) {
        self.config.setShortBreakMinutes(minutes)
        self.persistPreferences()
        self.handleConfigChangeWhileActiveTimer()
    }

    func updateLongBreakMinutes(_ minutes: Int) {
        self.config.setLongBreakMinutes(minutes)
        self.persistPreferences()
        self.handleConfigChangeWhileActiveTimer()
    }

    func updateLongBreakFrequency(_ frequency: Int) {
        self.config.longBreakFrequency = max(1, frequency)
        self.persistPreferences()
    }

    func updateAutoStart(_ autoStart: Bool) {
        self.config.autoStart = autoStart
        self.persistPreferences()
    }

    func updateNotificationSoundEnabled(_ enabled: Bool) {
        self.config.notificationSoundEnabled = enabled
        self.persistPreferences()
        self.requestNotificationPermissionAndScheduleIfNeeded()
    }

    func updateRespectFocusMode(_ enabled: Bool) {
        self.config.respectFocusMode = enabled
        self.persistPreferences()
        self.requestNotificationPermissionAndScheduleIfNeeded()
    }

    func updateNarrativeModeEnabled(_ enabled: Bool) {
        self.config.narrativeModeEnabled = enabled
        self.persistPreferences()
    }

    func requestFocusModeAuthorization() {
        self.focusModeService.requestAuthorizationIfNeeded { [weak self] status in
            Task { @MainActor in
                guard let self else {
                    return
                }
                self.focusModeStatus = status
                self.requestNotificationPermissionAndScheduleIfNeeded()
            }
        }
    }
}

extension TimerStore {
    private func startTickerIfNeeded() {
        guard self.ticker == nil else {
            return
        }

        self.ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else {
                return
            }

            Task { @MainActor in
                self.now = Date()
                self.processElapsedSessionsIfNeeded()
            }
        }
    }

    private func processElapsedSessionsIfNeeded() {
        while true {
            guard self.snapshot.timerState == .running,
                  let endDate = self.snapshot.endDate,
                  endDate <= self.now
            else {
                break
            }
            self.completeCurrentSession(at: endDate, dueToSkip: false)
        }
    }

    private func completeCurrentSession(at endedAt: Date, dueToSkip: Bool) {
        self.notificationService.cancelSessionEndNotification()
        let sourceState = self.snapshot.timerState

        let currentType = self.snapshot.sessionType
        let plannedDuration = TimerEngine.duration(for: currentType, config: self.config)
        self.persistRecordIfNeeded(
            currentType: currentType,
            endedAt: endedAt,
            plannedDuration: plannedDuration,
            dueToSkip: dueToSkip,
            sourceState: sourceState
        )

        let nextCompletedFocusCount = self.nextCompletedFocusCount(currentType: currentType, dueToSkip: dueToSkip)
        let nextType = TimerEngine.nextSessionType(
            current: currentType,
            completedFocusCount: nextCompletedFocusCount,
            config: self.config
        )

        let decision = TimerEngine.shouldStopAtBoundary(
            policy: self.snapshot.boundaryStopPolicy,
            nextSessionType: nextType,
            dueToSkip: dueToSkip,
            autoStart: self.config.autoStart
        )

        self.applyBoundaryTransition(
            BoundaryTransitionContext(
                endedAt: endedAt,
                nextType: nextType,
                nextCompletedFocusCount: nextCompletedFocusCount,
                decision: decision,
                dueToSkip: dueToSkip,
                sourceState: sourceState
            )
        )

        #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    private func persistRecordIfNeeded(
        currentType: SessionType,
        endedAt: Date,
        plannedDuration: Int,
        dueToSkip: Bool,
        sourceState: TimerState
    ) {
        guard let startedAt = self.snapshot.startedAt else {
            return
        }

        let actualDurationSec: Int
        switch sourceState {
        case .paused:
            let pausedRemaining = self.snapshot.pausedRemainingSec ?? plannedDuration
            actualDurationSec = max(0, plannedDuration - pausedRemaining)
        case .running, .idle:
            actualDurationSec = max(0, Int(endedAt.timeIntervalSince(startedAt)))
        }

        let payload = SessionRecordPayload(
            sessionType: currentType,
            startedAt: startedAt,
            endedAt: endedAt,
            plannedDurationSec: plannedDuration,
            actualDurationSec: actualDurationSec,
            completed: !dueToSkip,
            skipped: dueToSkip
        )
        self.persistSessionRecord(payload)
    }

    private func nextCompletedFocusCount(currentType: SessionType, dueToSkip _: Bool) -> Int {
        guard currentType == .focus else {
            return self.snapshot.completedFocusCount
        }

        return self.snapshot.completedFocusCount + 1
    }

    private func applyBoundaryTransition(_ context: BoundaryTransitionContext) {
        self.snapshot.completedFocusCount = context.nextCompletedFocusCount
        self.snapshot.sessionType = context.nextType
        self.snapshot.pausedRemainingSec = nil

        if context.decision.consumePolicy {
            self.snapshot.boundaryStopPolicy = .none
            self.persistPreferences()
        }

        if context.dueToSkip, context.sourceState == .paused {
            let nextDuration = TimerEngine.duration(for: context.nextType, config: self.config)
            self.snapshot.timerState = .paused
            self.snapshot.startedAt = nil
            self.snapshot.endDate = nil
            self.snapshot.pausedRemainingSec = nextDuration
            self.syncLiveActivity()
            self.syncAmbientNoise()
            return
        }

        if context.decision.shouldStop {
            self.snapshot.timerState = .idle
            self.snapshot.startedAt = nil
            self.snapshot.endDate = nil
            self.syncLiveActivity()
            self.syncAmbientNoise()
            return
        }

        let nextDuration = TimerEngine.duration(for: context.nextType, config: self.config)
        self.snapshot.timerState = .running
        self.snapshot.startedAt = context.endedAt
        self.snapshot.endDate = context.endedAt.addingTimeInterval(TimeInterval(nextDuration))
        self.requestNotificationPermissionAndScheduleIfNeeded()
        self.syncLiveActivity()
        self.syncAmbientNoise()
    }

    private func handleConfigChangeWhileActiveTimer() {
        let currentType = self.snapshot.sessionType
        let fallback = TimerEngine.duration(for: currentType, config: self.config)

        switch self.snapshot.timerState {
        case .idle:
            return
        case .running:
            let remaining = self.remainingSeconds
            let now = Date()
            self.snapshot.endDate = now.addingTimeInterval(TimeInterval(max(1, min(remaining, fallback))))
            self.requestNotificationPermissionAndScheduleIfNeeded()
        case .paused:
            self.snapshot.pausedRemainingSec = max(1, min(self.snapshot.pausedRemainingSec ?? fallback, fallback))
        }

        self.syncLiveActivity()
    }
}

extension TimerStore {
    func updateAmbientNoiseEnabled(_ enabled: Bool) {
        self.config.ambientNoiseEnabled = enabled
        self.persistPreferences()
        self.syncAmbientNoise()
    }

    func updateAmbientNoiseVolume(_ volume: Double) {
        self.config.ambientNoiseVolume = volume
        self.persistPreferences()
        #if os(iOS) || os(macOS)
            self.ambientNoiseService.setVolume(volume)
        #endif
    }
}

extension TimerStore {
    /// Start or stop ambient noise based on current timer state and config.
    ///
    /// Noise plays only when: ambient noise is enabled, the current session is focus, and the timer is running.
    private func syncAmbientNoise() {
        #if os(iOS) || os(macOS)
            let shouldPlay = self.config.ambientNoiseEnabled
                && self.snapshot.sessionType == .focus
                && self.snapshot.timerState == .running

            if shouldPlay {
                self.ambientNoiseService.start(volume: self.config.ambientNoiseVolume)
            } else {
                self.ambientNoiseService.stop()
            }
        #endif
    }
}

extension TimerStore {
    private func requestNotificationPermissionAndScheduleIfNeeded() {
        guard self.snapshot.timerState == .running, let endDate = self.snapshot.endDate else {
            self.notificationService.cancelSessionEndNotification()
            return
        }

        let sessionType = self.snapshot.sessionType
        self.notificationService.requestAuthorizationIfNeeded { [weak self] state in
            Task { @MainActor in
                guard let self else {
                    return
                }

                self.notificationAuthorizationState = state
                guard state == .authorized else {
                    return
                }

                self.notificationService.scheduleSessionEndNotification(
                    sessionType: sessionType,
                    fireDate: endDate,
                    soundEnabled: self.effectiveNotificationSoundEnabled
                )
            }
        }
    }

    private func refreshNotificationAuthorizationState() {
        self.notificationService.refreshAuthorizationState { [weak self] state in
            Task { @MainActor in
                self?.notificationAuthorizationState = state
            }
        }
    }

    private func refreshFocusModeStatus() {
        self.focusModeService.refreshStatus { [weak self] status in
            Task { @MainActor in
                guard let self else {
                    return
                }

                self.focusModeStatus = status
                self.requestNotificationPermissionAndScheduleIfNeeded()
            }
        }
    }
}
