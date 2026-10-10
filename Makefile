# Agent Usage — developer tasks.  Run `make help` to list them.

APP        := AgentUsage
SPEC       := agentusage.yml
PROJECT    := $(APP).xcodeproj
BUNDLE_ID  := dev.agus.AgentUsage
DERIVED    := .build/xcode
DEBUG_APP  := $(DERIVED)/Build/Products/Debug/$(APP).app
RELEASE_APP:= $(DERIVED)/Build/Products/Release/$(APP).app
DIST       := dist
PATH       := /opt/homebrew/bin:/usr/local/bin:$(PATH)

.DEFAULT_GOAL := help
.PHONY: help setup generate open build release run run-release swift-build swift-run \
        format lint install uninstall zip dmg reset-onboarding reset clean distclean

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make \033[36m<target>\033[0m\n\n"} \
		/^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Install XcodeGen via Homebrew if missing
	@command -v xcodegen >/dev/null || brew install xcodegen
	@echo "xcodegen: $$(xcodegen --version)"

generate: ## Generate the Xcode project from agentusage.yml
	xcodegen generate --spec $(SPEC)

open: generate ## Generate and open the project in Xcode
	open $(PROJECT)

build: generate ## Build the Debug app with xcodebuild
	xcodebuild -project $(PROJECT) -scheme $(APP) -configuration Debug -derivedDataPath $(DERIVED) build | tail -3

release: generate ## Build the Release app with xcodebuild
	xcodebuild -project $(PROJECT) -scheme $(APP) -configuration Release -derivedDataPath $(DERIVED) build | tail -3

run: build ## Build and launch the Debug app
	-pkill -x $(APP)
	open $(DEBUG_APP)

run-release: release ## Build and launch the Release app
	-pkill -x $(APP)
	open $(RELEASE_APP)

swift-build: ## Build with SwiftPM (no Xcode project needed)
	swift build

swift-run: ## Run with SwiftPM
	swift run

format: ## Format all Swift sources with swift-format
	swift format format -i -r Sources

lint: ## Check formatting without changing files
	swift format lint -r Sources

install: release ## Install the Release app into /Applications
	-pkill -x $(APP)
	rm -rf /Applications/$(APP).app
	cp -R $(RELEASE_APP) /Applications/$(APP).app
	@echo "Installed /Applications/$(APP).app"

uninstall: ## Remove the app from /Applications
	-pkill -x $(APP)
	rm -rf /Applications/$(APP).app

zip: release ## Package the Release app into dist/AgentUsage.zip
	mkdir -p $(DIST)
	ditto -c -k --keepParent $(RELEASE_APP) $(DIST)/$(APP).zip
	@echo "Created $(DIST)/$(APP).zip"

dmg: release ## Package the Release app into dist/AgentUsage.dmg
	mkdir -p $(DIST) .build/dmg
	rm -rf .build/dmg/* $(DIST)/$(APP).dmg
	cp -R $(RELEASE_APP) .build/dmg/
	ln -s /Applications .build/dmg/Applications
	hdiutil create -volname "$(APP)" -srcfolder .build/dmg -ov -format UDZO $(DIST)/$(APP).dmg
	@echo "Created $(DIST)/$(APP).dmg"

reset-onboarding: ## Show the first-launch walkthrough again
	-defaults delete $(BUNDLE_ID) onboarded

reset: ## Clear all saved preferences (integrations stay in Keychain)
	-defaults delete $(BUNDLE_ID)

clean: ## Remove build products
	rm -rf .build $(DIST)

distclean: clean ## Also remove the generated Xcode project and plists
	rm -rf $(PROJECT) Info.plist $(APP).entitlements
