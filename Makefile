PREFIX ?= $(HOME)/.local
CC ?= cc
CFLAGS ?= -O2 -Wall

NAME := linux-discord-game-detection-fix
SCRIPTS := $(wildcard bin/*)
APPS := $(HOME)/.local/share/applications
SOBER_DESKTOP := /var/lib/flatpak/exports/share/applications/org.vinegarhq.Sober.desktop

all: build/idle

build/idle: src/idle.c
	mkdir -p build
	$(CC) $(CFLAGS) -o $@ $<

install: build/idle
	install -Dm755 build/idle $(PREFIX)/libexec/$(NAME)/idle
	install -Dm755 -t $(PREFIX)/bin $(SCRIPTS)

uninstall:
	rm -f $(addprefix $(PREFIX)/bin/,$(notdir $(SCRIPTS)))
	rm -rf $(PREFIX)/libexec/$(NAME)

# Makes Sober's menu entry and roblox:// links go through sober-discord.
install-sober-desktop:
	mkdir -p $(APPS)
	sed 's|^Exec=.* -- @@u %u @@$$|Exec=$(PREFIX)/bin/sober-discord %u|' $(SOBER_DESKTOP) > $(APPS)/org.vinegarhq.Sober.desktop
	-update-desktop-database $(APPS)

uninstall-sober-desktop:
	rm -f $(APPS)/org.vinegarhq.Sober.desktop
	-update-desktop-database $(APPS)

clean:
	rm -rf build

.PHONY: all install uninstall install-sober-desktop uninstall-sober-desktop clean
