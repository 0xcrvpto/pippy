# Pippy

I built Pippy as a small, friendly reminder to take care of yourself while you work.

Rally nudges you to move, Blink guides a 20-second eye break, and Mochi reminds you to stretch. Each buddy has soft artwork and gentle animation, with snooze controls and optional sound. Blink plays soft, original cues at the start, halfway through, and when the break is done. Each buddy can have its own sound (Soft Bells, Marimba, Wind Chimes, Kalimba, or Woodblock), and you can preview them all in Preferences.

## Install

Pippy is publicly available from [Releases](https://github.com/0xcrvpto/pippy/releases/latest).

| Platform | Download | Requirements |
| --- | --- | --- |
| macOS | [Mac disk image](https://github.com/0xcrvpto/pippy/releases/latest/download/Pippy-0.6.2-arm64.dmg) | Apple silicon, macOS 13+ |

Quit any running copy before installing. Open the `.dmg` and drag Pippy onto the Applications folder in the window that appears, then eject the disk image. Prefer an installer? `Pippy-<version>-arm64.pkg` on the release page installs Pippy into Applications.

These are early, unsigned releases: Pippy is not Developer ID signed or notarized, so macOS may show a security warning. If Pippy won't open the first time, go to System Settings › Privacy & Security and choose **Open Anyway**.

## Use

Open Pippy from Applications. Adjust reminders, each buddy's active hours, and its sound in Preferences — scroll, drag, or click any time or interval chip to change it — or preview each buddy from the menu-bar menu. Closing the window keeps reminders running; choose **Quit Pippy** to stop them.

Each buddy only nudges inside its own active hours, which you can change in Preferences (overnight schedules work too). By default Rally runs 2–6 p.m., and Blink and Mochi run 11 a.m.–11 p.m. Snoozes last for the current app session. macOS Reduce Motion disables mascot movement.

The app stores settings locally and does not require an account. Once a day it asks GitHub whether a newer release exists and, if so, shows an update banner with a download button; nothing about you is sent. You can also choose **Check for Updates** from the menu-bar menu. Updates are not installed automatically: download the new version and install it over the old one, and your settings carry over.

## Feedback

Found a bug, something confusing, or have an idea? Use **Feedback** in the app or menu bar, or reach out directly:

- Email: [0xcrvpto@webuild3.xyz](mailto:0xcrvpto@webuild3.xyz)
- Telegram: [t.me/i0xcrvpto](https://t.me/i0xcrvpto)

[Build and packaging notes](docs/development.md)
