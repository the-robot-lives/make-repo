INSTALL_DIR := $(HOME)/.local/bin

.PHONY: compile test install

compile:
	@true

test:
	@if bash -c '[[ $${BASH_VERSINFO[0]} -ge 4 ]]' 2>/dev/null; then bash tests/run.sh; \
	elif [ -x /opt/homebrew/bin/bash ]; then /opt/homebrew/bin/bash tests/run.sh; \
	else echo "make-repo tests need Bash 4+ (macOS /bin/bash is 3.2)" >&2; exit 1; fi

install:
	@mkdir -p $(INSTALL_DIR)
	@src=$$(realpath bin/make-repo); dst=$$(realpath $(INSTALL_DIR)/make-repo 2>/dev/null); \
	if [ "$$src" = "$$dst" ]; then \
		echo "make-repo: already installed (same file) — skipping"; \
	else \
		install -m 755 bin/make-repo $(INSTALL_DIR)/make-repo; \
	fi
	@src=$$(realpath bin/fork-repo); dst=$$(realpath $(INSTALL_DIR)/fork-repo 2>/dev/null); \
	if [ "$$src" = "$$dst" ]; then \
		echo "fork-repo: already installed (same file) — skipping"; \
	else \
		install -m 755 bin/fork-repo $(INSTALL_DIR)/fork-repo; \
	fi
