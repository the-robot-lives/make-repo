INSTALL_DIR := $(HOME)/.local/bin

.PHONY: compile test install

compile:
	@true

test:
	@true

install:
	@mkdir -p $(INSTALL_DIR)
	cp bin/make-repo $(INSTALL_DIR)/
	chmod +x $(INSTALL_DIR)/make-repo
