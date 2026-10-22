# Pippy

I built Pippy as a small, friendly reminder to take care of yourself while you work.

Rally nudges you to move, Blink guides a 20-second eye break, and Mochi reminds you to stretch. Each buddy has soft artwork and gentle animation, with snooze controls and optional sound. Blink plays soft, original cues at the start, halfway through, and when the break is done. Each buddy can have its own sound (Soft Bells, Marimba, Wind Chimes, Kalimba, or Woodblock), and you can preview them all in Preferences.

## Install

Pippy is publicly available from [Releases](https://github.com/0xcrvpto/pippy/releases/latest).

| Platform | Download | Requirements |
| --- | --- | --- |
| macOS | [Mac disk image](https://github.com/0xcrvpto/pippy/releases/latest/download/Pippy-0.6.2-arm64.dmg) | Apple silicon, macOS 13+ |
| Windows | [Windows installer](https://github.com/0xcrvpto/pippy/releases/latest/download/Pippy-0.6.2-Windows-x64-Setup.exe) or [portable ZIP](https://github.com/0xcrvpto/pippy/releases/latest/download/Pippy-0.6.2-Windows-x64-Portable.zip) | Windows 10 version 2004+ or Windows 11, x64 |

Quit any running copy before installing. On Mac, open the `.dmg` and drag Pippy onto the Applications folder in the window that appears, then eject the disk image. On Windows, open the setup `.exe`; it installs for your user and adds a Start menu shortcut. Prefer not to install? Unzip the portable ZIP anywhere (for example your Documents folder) and run `Pippy.exe`. The Windows runtime is included in both.

These are early, unsigned releases. The Mac build is not Developer ID signed or notarized; Windows has no Authenticode signature. Your operating system may show a security warning. On Mac, if Pippy won't open the first time, go to System Settings › Privacy & Security and choose **Open Anyway**.

### If Windows blocks the installer

If setup stops with **"Unable to execute file in the temporary directory. Setup aborted. Error 5: Access is denied"**, something on that PC is blocking unsigned programs from running. Pippy isn't damaged. Try these in order:

1. **Unblock the download.** Right-click the setup `.exe`, choose **Properties**, tick **Unblock** if it's there, select **OK**, and run it again.
2. **Use the portable ZIP.** It runs without an installer, which avoids most antivirus rules that block setup programs in the temporary folder.
3. **Check your antivirus.** Third-party antivirus or a work-managed PC may quarantine unsigned apps. Allow Pippy, or ask your IT team.
4. **Check Smart App Control.** On Windows 11, open **Windows Security › App & browser control › Smart App Control**. If it's **On**, Windows blocks every unsigned app, including the portable ZIP. A code-signed Pippy is planned. Turning Smart App Control off works too, but on some Windows versions it can't be switched back on without resetting Windows, so only do that if you're comfortable with it.

## Use

Open Pippy from Applications on Mac or the Start menu on Windows. Adjust reminders, each buddy's active hours, and its sound in Preferences — scroll, drag, or click any time or interval chip to change it — or preview each buddy from the menu-bar or system-tray menu. Closing the window keeps reminders running; choose **Quit Pippy** to stop them.

Each buddy only nudges inside its own active hours, which you can change in Preferences (overnight schedules work too). By default Rally runs 2–6 p.m., and Blink and Mochi run 11 a.m.–11 p.m. Snoozes last for the current app session. macOS Reduce Motion disables mascot movement; Windows has a Reduce Motion preference.

The app stores settings locally and does not require an account. Once a day it asks GitHub whether a newer release exists and, if so, shows an update banner with a download button; nothing about you is sent. You can also choose **Check for Updates** from the menu-bar or tray menu. Updates are not installed automatically: download the new version and install it over the old one, and your settings carry over.

## Feedback

Found a bug, something confusing, or have an idea? Use **Feedback** in the app or menu bar, or reach out directly:

- Email: [0xcrvpto@webuild3.xyz](mailto:0xcrvpto@webuild3.xyz)
- Telegram: [t.me/i0xcrvpto](https://t.me/i0xcrvpto)

[Build and packaging notes](docs/development.md)
