# Development

The maintained project contains:

- `Sources/`: native AppKit app and reminder logic.
- `Assets/`: current app icon and three mascot images.
- `Packaging/Info.plist`: app metadata; the existing bundle identifier preserves local settings.
- `Scripts/`: reproducible build, icon, test, preview, and installer commands.
- `dist/`: generated app and installer, excluded from Git.

From the project root on macOS with Apple command-line developer tools:

```sh
./Scripts/check.sh
./Scripts/preview.sh
./Scripts/package-dmg.sh
./Scripts/package.sh
```

The check covers custom and overnight workout windows, invalid inputs, persistence, audio decoding for every sound set, per-buddy sound choices, the scroll picker (stepping, midnight wrap, skipping a matching start/end, interval clamping), the feedback links, a full eye-break countdown, cue order, and snooze actions. The preview renders each card. `package-dmg.sh` builds the app and a drag-to-Applications disk image: the app, an `Applications` link, a rendered background (`Scripts/dmg-background.swift`), and a volume icon, laid out by a Finder AppleScript. The first run asks to let your terminal control Finder; if that is denied the DMG still works with a plain window. `package.sh` builds the alternative installer package: it compiles for Apple silicon, generates the icon with Apple's iconutil, ad-hoc signs and verifies the app, and builds an installer targeting `/Applications/Pippy.app`.

The installer disables bundle relocation so it does not overwrite a Desktop development copy. It has no install scripts and does not launch the app or change login items. Outputs include a SHA-256 checksum.

Ad-hoc signing is not Developer ID signing. Public friction-free distribution requires an Apple Developer ID Application certificate, a Developer ID Installer certificate, and notarization. None is bundled in this repository.

The update check (`Sources/Updates.swift`, `Updates` in `Windows/Model.cs`) reads `releases/latest` from the GitHub API, ignores drafts and pre-releases, compares versions numerically, and links to the release asset ending in `-arm64.dmg` or `-Windows-x64-Setup.exe` (falling back to the release page). Releases must therefore be published as regular, non-pre-release GitHub releases with those asset names.

Mascot animations transform complete artwork, not independently rigged facial features. Snoozes are in-memory. Workout hours are configurable and saved locally; eye and stretch hours remain fixed.

Audio assets in `Assets/Sounds/` are original synthesized WAV files in five sets (`Blink*` is Soft Bells, plus `Marimba*`, `Chimes*`, `Kalimba*`, `Woodblock*`), each with start, halfway, complete, and preview cues. Regenerate them with `python3 Scripts/generate-sounds.py`; the `Blink*` files are unchanged byte for byte. Each buddy's set is saved under `sound.<kind>`. Explicit sound previews play even when reminder sounds are muted; automatic cues respect mute.

## Windows

`Windows/` contains the native WPF app targeting .NET 10. It shares artwork, all five sound sets, feedback links, and the scroll-picker behaviour with macOS, and stores settings under `%LOCALAPPDATA%\Pippy`. The per-user Inno Setup installer includes the runtime and adds a Start menu shortcut.

On Windows with the .NET 10 SDK and Inno Setup 6:

```powershell
dotnet publish Windows/Pippy.csproj -c Release -r win-x64 --self-contained true -o dist/windows/publish
& dist/windows/publish/Pippy.exe --self-test
& dist/windows/publish/Pippy.exe --smoke-test previews
& "${env:ProgramFiles(x86)}/Inno Setup 6/ISCC.exe" Windows/installer.iss
```

The Windows GitHub Actions workflow builds the app, tests scheduling and persistence, decodes embedded assets, runs the actual 20-second countdown, renders the UI, and silently installs, tests, and uninstalls the package. It uploads the installer, checksum, and rendered previews as run artifacts. Manual dispatch can attach the installer to an existing release tag. The installer is not Authenticode signed.
