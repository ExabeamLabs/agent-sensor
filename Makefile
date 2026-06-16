.DEFAULT_GOAL := help

# VERSION must be supplied on the command line, e.g. make release VERSION=1.2.3
VERSION ?= $(error VERSION is required. Usage: make release VERSION=1.2.3)

TAG     := v$(VERSION)
BIN_DIR := bin

MACOS_INTEL := $(BIN_DIR)/aba-sensor-$(TAG)-x86_64-apple-darwin
MACOS_ARM   := $(BIN_DIR)/aba-sensor-$(TAG)-aarch64-apple-darwin
WINDOWS     := $(BIN_DIR)/aba-sensor-$(TAG)-x86_64-pc-windows-gnu.exe

BINS := $(MACOS_INTEL) $(MACOS_ARM) $(WINDOWS)

# ── Targets ──────────────────────────────────────────────────────────────────

.PHONY: help verify tag gh-release release

help:
	@echo ""
	@echo "  aba-sensor-dist release workflow"
	@echo ""
	@echo "  Targets:"
	@echo "    make verify      VERSION=x.y.z   Check that all three binaries exist in bin/"
	@echo "    make tag         VERSION=x.y.z   Create and push the git tag"
	@echo "    make gh-release  VERSION=x.y.z   Create GitHub Release and upload binaries"
	@echo "    make release     VERSION=x.y.z   Full flow: verify → tag → gh-release"
	@echo ""
	@echo "  Before running 'make release':"
	@echo "    1. Build binaries in the private repo and copy them to bin/ with the"
	@echo "       naming convention above."
	@echo "    2. Update docs/changelog.md with release notes."
	@echo ""

verify:
	@echo "==> Checking prerequisites..."
	@command -v gh >/dev/null 2>&1 || { echo "ERROR: 'gh' (GitHub CLI) is not installed. See https://cli.github.com"; exit 1; }
	@gh auth status >/dev/null 2>&1 || { echo "ERROR: Not authenticated with gh. Run: gh auth login"; exit 1; }
	@echo "==> Verifying binaries for $(TAG)..."
	@for f in $(BINS); do \
		if [ ! -f "$$f" ]; then \
			echo "ERROR: Missing binary: $$f"; \
			exit 1; \
		fi; \
		echo "  OK  $$f"; \
	done
	@echo "==> All binaries present."

tag:
	@echo "==> Tagging $(TAG)..."
	@git diff --quiet && git diff --cached --quiet || { echo "ERROR: Working tree has uncommitted changes. Commit or stash first."; exit 1; }
	@git tag -a $(TAG) -m "Release $(TAG)"
	@git push origin $(TAG)
	@echo "==> Tag $(TAG) pushed."

gh-release:
	@echo "==> Creating GitHub Release $(TAG)..."
	@gh release create $(TAG) $(BINS) \
		--title "$(TAG)" \
		--notes-file docs/changelog.md
	@echo "==> Release $(TAG) published."
	@echo "    https://github.com/ExabeamLabs/aba-sensor-dist/releases/tag/$(TAG)"

release: verify tag gh-release
	@echo ""
	@echo "==> Release $(TAG) complete."
