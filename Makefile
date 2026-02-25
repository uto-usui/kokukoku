SHELL := /bin/zsh

PROJECT_DIR := app/Kokukoku
PROJECT_FILE := $(PROJECT_DIR)/Kokukoku.xcodeproj
SCHEME := Kokukoku
CONFIGURATION := Debug
MAC_DESTINATION := platform=macOS
IOS_DESTINATION := generic/platform=iOS Simulator
UNIT_TEST_TARGET := KokukokuTests

.PHONY: help bootstrap doctor open-xcode open-cursor format lint build-macos build-ios test-macos test-ui-macos ci clean

help:
	@echo "Available targets:"
	@echo "  make bootstrap   Install required CLI tools"
	@echo "  make doctor      Check local dev environment"
	@echo "  make format      Run swiftformat on app code"
	@echo "  make lint        Run swiftlint"
	@echo "  make build-macos Build app for macOS"
	@echo "  make build-ios   Build app for iOS Simulator (includes Watch/Widget)"
	@echo "  make test-macos  Run unit tests for macOS destination"
	@echo "  make test-ui-macos Run UI tests for macOS destination"
	@echo "  make ci          Run lint + tests (CI local equivalent)"
	@echo "  make open-xcode  Open this repo in Xcode"
	@echo "  make open-cursor Open this repo in Cursor"

bootstrap:
	./scripts/bootstrap_macos.sh

doctor:
	./scripts/doctor.sh

format:
	swiftformat $(PROJECT_DIR)

lint:
	swiftlint lint --strict --config .swiftlint.yml

build-macos:
	xcodebuild -project "$(PROJECT_FILE)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" -destination "$(MAC_DESTINATION)" build | xcbeautify

build-ios:
	xcodebuild -project "$(PROJECT_FILE)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" -destination "$(IOS_DESTINATION)" build | xcbeautify

test-macos:
	xcodebuild -project "$(PROJECT_FILE)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" -destination "$(MAC_DESTINATION)" -only-testing:"$(UNIT_TEST_TARGET)" test | xcbeautify

test-ui-macos:
	xcodebuild -project "$(PROJECT_FILE)" -scheme "$(SCHEME)" -configuration "$(CONFIGURATION)" -destination "$(MAC_DESTINATION)" -only-testing:"KokukokuUITests" test | xcbeautify

ci: lint test-macos build-ios

clean:
	xcodebuild -project "$(PROJECT_FILE)" -scheme "$(SCHEME)" clean | xcbeautify

open-xcode:
	open -a Xcode .

open-cursor:
	cursor .
