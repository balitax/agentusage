# Agent Usage — developer tasks.  Run `make help` to list them.

APP        := AgentUsage
SPEC       := agentusage.yml
PROJECT    := $(APP).xcodeproj
BUNDLE_ID  := dev.agus.AgentUsage
DERIVED    := .build/xcode
DEBUG_APP  := $(DERIVED)/Build/Products/Debug/$(APP).app
RELEASE_APP:= $(DERIVED)/Build/Products/Release/$(APP).app
DIST       := dist
VERSION    := $(shell sed -n 's/.*MARKETING_VERSION: *"\(.*\)"/\1/p' $(SPEC) | head -1)
TAG        := v$(VERSION)
REPO       := balitax/agentusage
PATH       := /opt/homebrew/bin:/usr/local/bin:$(PATH)

.DEFAULT_GOAL := help
.PHONY: help setup generate open build release run run-release swift-build swift-run \
        test test-xcode format lint install uninstall zip dmg reset-onboarding reset clean distclean version checksums publish

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

test: ## Run unit tests with SwiftPM
	swift test

test-xcode: generate ## Run unit tests with xcodebuild
	xcodebuild test -project $(PROJECT) -scheme $(APP) -destination 'platform=macOS' -derivedDataPath $(DERIVED) | tail -8

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

version: ## Print the app version from agentusage.yml
	@echo $(VERSION)

zip: release ## Package the Release app into dist/AgentUsage-<version>.zip
	mkdir -p $(DIST)
	ditto -c -k --keepParent $(RELEASE_APP) $(DIST)/$(APP)-$(VERSION).zip
	@echo "Created $(DIST)/$(APP)-$(VERSION).zip"

dmg: release ## Package the Release app into dist/AgentUsage-<version>.dmg
	mkdir -p $(DIST) .build/dmg
	rm -rf .build/dmg/* $(DIST)/$(APP)-$(VERSION).dmg
	cp -R $(RELEASE_APP) .build/dmg/
	ln -s /Applications .build/dmg/Applications
	hdiutil create -volname "$(APP)" -srcfolder .build/dmg -ov -format UDZO $(DIST)/$(APP)-$(VERSION).dmg
	@echo "Created $(DIST)/$(APP)-$(VERSION).dmg"

checksums: ## Write dist/SHA256SUMS.txt for the dmg and zip
	cd $(DIST) && shasum -a 256 $(APP)-$(VERSION).dmg $(APP)-$(VERSION).zip > SHA256SUMS.txt
	@cat $(DIST)/SHA256SUMS.txt

publish: ## Tag v<version> and create a GitHub release (NOTES=file.md optional)
	@test -z "$$(git status --porcelain)" || (echo "Working tree is not clean. Commit first."; exit 1)
	@git rev-parse $(TAG) >/dev/null 2>&1 && (echo "Tag $(TAG) already exists. Bump MARKETING_VERSION in $(SPEC)."; exit 1) || true
	$(MAKE) clean dmg zip checksums
	git tag -a $(TAG) -m "$(APP) $(VERSION)"
	git push origin main $(TAG)
	gh release create $(TAG) $(DIST)/$(APP)-$(VERSION).dmg $(DIST)/$(APP)-$(VERSION).zip $(DIST)/SHA256SUMS.txt \
		--repo $(REPO) --title "$(APP) $(VERSION)" \
		$(if $(NOTES),--notes-file $(NOTES),--generate-notes)

reset-onboarding: ## Show the first-launch walkthrough again
	-defaults delete $(BUNDLE_ID) onboarded

reset: ## Clear all saved preferences (integrations stay in Keychain)
	-defaults delete $(BUNDLE_ID)

clean: ## Remove build products
	rm -rf .build $(DIST)

distclean: clean ## Also remove the generated Xcode project and plists
	rm -rf $(PROJECT) Info.plist $(APP).entitlements
