# Pippy

I built Pippy as a small, friendly reminder to take care of yourself while you work.

Rally nudges you to move, Blink guides a 20-second eye break, and Mochi reminds you to stretch. Each buddy has soft artwork and gentle animation, with snooze controls and optional sound. Blink plays soft, original cues at the start, halfway through, and when the break is done. Each buddy can have its own sound (Soft Bells, Marimba, Wind Chimes, Kalimba, or Woodblock), and you can preview them all in Preferences.

## Install

Pippy is publicly available from [Releases](https://github.com/0xcrvpto/pippy/releases/latest).

| Platform | Download | Requirements |
| --- | --- | --- |
| macOS | [Mac disk image](https://github.com/0xcrvpto/pippy/releases/latest/download/Pippy-0.6-arm64.dmg) | Apple silicon, macOS 13+ |
| Windows | [Windows installer](https://github.com/0xcrvpto/pippy/releases/download/v0.5.0/Pippy-0.5-Windows-x64-Setup.exe) | Windows 10 version 2004+ or Windows 11, x64 |

Quit any running copy before installing. On Mac, open the `.dmg` and drag Pippy onto the Applications folder in the window that appears, then eject the disk image. On Windows, open the setup `.exe`; it installs for your user and adds a Start menu shortcut. The Windows runtime is included.

These are early, unsigned releases. The Mac build is not Developer ID signed or notarized; Windows has no Authenticode signature. Your operating system may show a security warning. On Mac, if Pippy won't open the first time, go to System Settings › Privacy & Security and choose **Open Anyway**.

## Use

Open Pippy from Applications on Mac or the Start menu on Windows. Adjust reminders, workout hours, and each buddy's sound in Preferences — scroll, drag, or click any time or interval chip to change it — or preview each buddy from the menu-bar or system-tray menu. Closing the window keeps reminders running; choose **Quit Pippy** to stop them.

Eye and stretch reminders run from 11 a.m. to 11 p.m.; workout hours are adjustable in Preferences (including overnight schedules), with 2–6 p.m. as the default. Snoozes last for the current app session. macOS Reduce Motion disables mascot movement; Windows has a Reduce Motion preference.

The app stores settings locally and does not require an account or network connection.

## Feedback

Found a bug, something confusing, or have an idea? Use **Feedback** in the app or menu bar, or reach out directly:

- Email: [0xcrvpto@webuild3.xyz](mailto:0xcrvpto@webuild3.xyz)
- Telegram: [t.me/i0xcrvpto](https://t.me/i0xcrvpto)

[Build and packaging notes](docs/development.md)
