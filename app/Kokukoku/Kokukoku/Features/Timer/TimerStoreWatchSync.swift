import Foundation

extension TimerStore {
    func handleWatchCommand(_ command: WatchTimerCommand) {
        switch command {
        case .primaryAction:
            self.performPrimaryAction()
        case .reset:
            self.reset()
        case .skip:
            self.skip()
        }
    }

    func syncLiveActivity() {
        self.liveActivityService.sync(snapshot: self.snapshot)
        self.watchConnectivityService.sync(snapshot: self.snapshot, config: self.config, now: self.now)
    }
}
