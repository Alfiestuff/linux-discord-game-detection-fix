# linux-discord-game-detection-fix

Makes Discord on Linux show the game you're playing ("Playing ROBLOX", "Playing Minecraft", ...)
under its official name.

Works with Proton games, Sober (Roblox) and Prism Launcher (Minecraft). Nothing is injected
into Discord or the game.

> **You need the native Discord app.** The Flatpak version can't see other programs, so it
> will never detect games.

## Install

Needs `gcc`, `make`, `python3` and `bash`.

```sh
git clone https://github.com/<you>/linux-discord-game-detection-fix
cd linux-discord-game-detection-fix
make install
```

Make sure `~/.local/bin` is on your `PATH`.

## Setup

### Roblox (Sober)

```sh
make install-sober-desktop
```

Launch Sober from your app menu as usual. Turn off Sober's own Discord Rich Presence setting.

### Minecraft (Prism Launcher)

Prism → Settings → Custom commands → **Wrapper command**:

```
/home/<you>/.local/bin/prism-discord
```

### Steam and other games

Look the game up to get the exact command to use:

```sh
discord-game-lookup <game name>
```

Paste the line it prints into the game's Steam **Launch options**. For example:

```
steam-discord 1468445147594494213 Gnomium.exe %command%
```

## Check it's working

```sh
discord-detection-log
```

This prints the game Discord currently shows as "Playing".

## Uninstall

```sh
make uninstall
make uninstall-sober-desktop
rm -rf ~/.local/share/linux-discord-game-detection-fix ~/.cache/linux-discord-game-detection-fix
```

Then remove the wrapper from any Steam launch options and from Prism.
