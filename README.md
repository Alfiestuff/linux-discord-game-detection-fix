# linux-discord-game-detection-fix

Make Discord on Linux show games as their **official** Discord entry ("Playing ROBLOX",
"Playing Minecraft", ...) instead of nothing, or a made-up name taken from the executable.

It works with Proton games, Flatpak games like Sober, and Java games through Prism Launcher.
Nothing is injected into Discord or the game. The tools only use Discord's normal process
scanner and its local Rich Presence socket.

## Why detection fails on Linux

There are three separate causes. The fix depends on which one you hit.

| Symptom | Cause | Fix |
| --- | --- | --- |
| No game is ever detected | Discord is the **Flatpak** build. It has its own PID namespace and can't see any process outside its sandbox. | Use the native Discord (`pacman -S discord` on Arch, or the `.deb`/`.tar.gz`). |
| Game is not detected (Sober, Minecraft) | Discord matches the **real executable path** (`/proc/<pid>/exe`) against its list of known executables. Those are usually Windows names like `RobloxPlayerBeta.exe`, which a Linux process never has. | `discord-fake-process`: run a tiny dummy process with the expected name while the game runs. |
| Game shows under the wrong name (e.g. *Gnomium* instead of *Burglin' Gnomes*) | The game's Discord entry lists **no executables**, so Discord falls back to the file name of the `.exe`. | `steam-discord` / `discord-presence`: tell Discord over the Rich Presence socket that the game's PID is the official app. |

Proton games whose Windows `.exe` is listed by Discord already work with native Discord.

## Install

Needs: native Discord, `gcc`, `make`, `python3`, `bash`, Linux 5.3+ (for `pidfd_open`), glibc 2.36+.

```sh
git clone https://github.com/<you>/linux-discord-game-detection-fix
cd linux-discord-game-detection-fix
make install            # installs to ~/.local (set PREFIX=... to change)
```

Make sure `~/.local/bin` is on your `PATH`.

## Find out what a game needs

```sh
discord-game-lookup roblox
discord-game-lookup --steam 3844970
discord-game-lookup --exe gnomium.exe
```

```
Burglin' Gnomes  (id 1468445147594494213)
  steam app id: 3844970
  fix: no executables listed; use: steam-discord 1468445147594494213 <process name> %command%
```

The list is downloaded from Discord's API and cached for a day (`--refresh` to update).

## Usage

### Any game: `discord-fake-process`

```sh
discord-fake-process <exe-name> [dummy args...] -- <command> [args...]
```

Starts a dummy whose executable is named `<exe-name>`, then `exec`s your command. The
dummy exits when the command exits, even when it is killed with `SIGKILL`. Some Discord
entries also need arguments on the command line (Minecraft does), so anything before `--`
is passed to the dummy. `discord-game-lookup` prints the exact line to use.

As Steam launch options, for a game Discord knows by a Windows `.exe`:

```
discord-fake-process somegame.exe -- %command%
```

### Roblox through Sober: `sober-discord`

```sh
sober-discord                 # run instead of `flatpak run org.vinegarhq.Sober`
make install-sober-desktop    # make the app menu and roblox:// links use it
```

Discord shows the official **ROBLOX** entry. Leave Sober's own Discord Rich Presence
setting off (`discord_rpc_enabled`), or you get a second, unofficial "Roblox" activity.

### Minecraft through Prism Launcher: `prism-discord`

Prism → Settings → Custom commands → **Wrapper command**:

```
/home/<you>/.local/bin/prism-discord
```

This applies to every instance that doesn't override custom commands. Discord shows the
official **Minecraft** entry. Prism still controls the Java process directly, so the Kill
button and the log window work as before.

### Games with no executables in Discord's list: `steam-discord`

Steam → game → Properties → **Launch options**:

```
steam-discord <discord app id> <process name> %command%
```

Example for Burglin' Gnomes, whose executable is `Gnomium.exe`:

```
steam-discord 1468445147594494213 Gnomium.exe %command%
```

It combines with other wrappers: `steam-discord ... mangohud %command%`.

`steam-discord` waits up to 3 minutes for a process with that name (the first 15
characters are matched, as in `/proc/<pid>/comm`). It then runs `discord-presence`, which
connects to Discord as the official app and passes the game's PID. Discord then treats the
detected process as that app. The wrong name disappears and you don't get a second
activity. If Discord restarts, the helper reconnects. When the game exits, the helper
exits too.

To find the process name, start the game and look in `ps -eo comm`.

## Checking that it works

```sh
discord-detection-log
```

This follows Discord's own log and prints the game Discord currently shows as "Playing",
plus the executable it matched:

```
2026-11-08 17:29:21.178  ROBLOX  (/home/you/.local/share/linux-discord-game-detection-fix/fake/robloxplayerbeta.exe:ROBLOX)
2026-11-08 17:29:36.175  null  (null)
```

Games set through `discord-presence` show here under the official name too, as long as the
PID belongs to a process Discord detected.

## Limitations

- The official entries only show the game name and elapsed time. Details such as which
  Roblox experience or Minecraft server you're in are not included.
- With `steam-discord`, don't stop `discord-presence` while the game runs. Discord keeps the
  process mapped to the app but then shows no activity at all.
- If a game renames its executable, Discord updates its list, and the dummy name has to
  change to match (`discord-game-lookup` shows the current one).
- Only tested with the native stable Discord client. Flatpak Discord can't work (see above).

## Uninstall

```sh
make uninstall
make uninstall-sober-desktop     # if you installed it
rm -rf ~/.local/share/linux-discord-game-detection-fix ~/.cache/linux-discord-game-detection-fix
```

Then remove the wrapper from any Steam launch options and from Prism's wrapper command.
