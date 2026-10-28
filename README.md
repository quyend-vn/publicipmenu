# Public IP

**Your public IP, right in the macOS menu bar. Click to copy.**

Public IP is a small native Mac app that does one thing simply: keeps your public IP address visible and ready to paste. No browser tab to open, no dashboard to navigate, and no account to create.

## Everyday use

1. Open **Public IP** from Applications.
2. See your public IP beside a small globe in the menu bar.
3. Click it to copy the address. Paste wherever you need it.

That's it. The app lives in the menu bar, with no Dock icon or main window.

Right-click for a few useful options:

| Option | What it does |
| --- | --- |
| **Copy IP** | Copies the displayed address. |
| **Refresh IP** | Checks your public IP immediately. |
| **Launch at Login** | Click to toggle automatic launch when you sign in. A checkmark means enabled. |
| **Quit Public IP** | Closes the app. |

**Launch at Login is enabled by default on the first launch.** Click **Launch at Login** to tick or untick it; your choice is kept between launches. There is no submenu. A dash means macOS approval is pending. If macOS asks for approval, use **Open Login Items Settings…** in the menu to approve it. Changes made in System Settings are respected.

## Small by design

- Native Swift and AppKit, using Apple's built-in frameworks.
- No third-party dependencies, account, ads, or analytics.
- Checks automatically about once a minute, when the Mac wakes, and when the network path changes.
- Shows a brief checkmark after copying.
- Reports connection failures and stops offering an outdated address for copying.
- English interface.

## Build and run

Requires **macOS 13 or later** and **Xcode Command Line Tools**. The build script targets the architecture of the Mac running it (Apple Silicon or Intel); it does not create a universal binary. Verification so far has been on Apple Silicon.

If needed, install Apple's command-line tools:

```sh
xcode-select --install
```

From the project folder:

```sh
./build.sh
open "/Applications/Public IP.app"
```

The script compiles the app, installs it into `/Applications`, and signs it ad-hoc for local use. Quit an existing running copy before rebuilding. Writing to `/Applications` requires permission to that folder.

For a user-only installation, use:

```sh
APP_PATH="$HOME/Applications/Public IP.app" ./build.sh
open "$HOME/Applications/Public IP.app"
```

Keep the app at the same installed location after enabling Launch at Login. To move it, turn that option off, move the app, and turn it on again.

## How the IP check works

Public IP requests `https://checkip.amazonaws.com/` over HTTPS and displays the address returned by that endpoint. It shows the public egress address seen by that service, which can be affected by a VPN, proxy, or your network routing. It does not inspect your local network addresses or verify whether a VPN is working.

The app keeps the fetched address in memory and writes it to the clipboard only when you choose to copy. It saves a small local preference to remember that the initial Launch at Login setup has been handled. There is no app-operated backend or analytics service. The IP-check provider necessarily receives the network request and sees its source IP; this README does not make promises about that provider's logging or retention.

## Distribution

The current build script is for building and running locally. A downloaded release for other users should be signed with a Developer ID and notarized. Mac App Store distribution needs its own signing, sandbox configuration, and review preparation.
