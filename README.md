# warpctl

> Not affiliated with, endorsed by, or supported by Cloudflare, Inc.

A tiny script to turn the Cloudflare WARP Linux client **off for good** — and back on again — without it quietly coming back on reboot.

## The problem

`warp-cli disconnect` only lasts until the next boot. The daemon has `Restart=always`, and the desktop taskbar app is started with your graphical session. So WARP reconnects whether you want it or not, and there is no official "disable permanently" switch.

`warpctl` fixes this by masking the systemd units that ship with the official `cloudflare-warp` package, which stops them from starting — at boot, on package upgrade, or when something tries to pull them in.

## Requirements

- Linux with **systemd** (also needs a user session bus for the desktop app — i.e. not a bare `ssh` login)
- The official **`cloudflare-warp`** package installed (`apt install cloudflare-warp`, `dnf install cloudflare-warp`, etc.)
- `sudo` access, for the system-level service

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/arnavsx3/warpctl/main/install.sh | bash
```

This installs to `~/.local/bin` and needs no `sudo`. Set `WARPCTL_VERSION=v1.0.0` to pin a release tag. Prefer not to pipe to bash?

```sh
git clone https://github.com/arnavsx3/warpctl
cd warpctl && ./install.sh
```

## Usage

```sh
warpctl off      # stop WARP and block it from starting
warpctl on       # unblock and start WARP again
warpctl status   # show whether each part is running and whether it can start
```

`status` reports running state and boot state separately, because `inactive` alone can't tell "stopped" from "blocked from ever starting":

```
  UNIT                   STATE     BOOT
  warp-svc.service       inactive  masked
  warp-taskbar.service   inactive  masked

WARP is off and will not start on boot.
```

`off` asks for `sudo` when it touches the system-level service; `on` does the same to restore it. The script refuses to run under `root` — run it as your normal user.

## How it works

Two units are involved:

| Unit | Scope | What it is |
| --- | --- | --- |
| `warp-svc.service` | system | The WARP daemon |
| `warp-taskbar.service` | user | The desktop app |

`off` runs `systemctl mask --now` on both. Masking symlinks the unit to `/dev/null`, so systemd refuses to load it at all — stronger than `disable`, which still allows a manual or dependency-driven start. `on` unmasks and starts them.

## Uninstall

```sh
warpctl on                                  # restore normal behaviour
rm ~/.local/bin/warpctl                     # remove the script
```

Nothing else is installed, and no configuration is modified.

## License

MIT
