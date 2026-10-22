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
./Scripts/package.sh
```

The check covers custom and overnight workout windows, invalid inputs, persistence, audio decoding, a full eye-break countdown, cue order, and snooze actions. The preview renders each card. Packaging compiles for Apple silicon, generates the icon with Apple's iconutil, ad-hoc signs and verifies the app, and builds an installer targeting `/Applications/Pippy.app`.

The installer disables bundle relocation so it does not overwrite a Desktop development copy. It has no install scripts and does not launch the app or change login items. Outputs include a SHA-256 checksum.

Ad-hoc signing is not Developer ID signing. Public friction-free distribution requires an Apple Developer ID Application certificate, a Developer ID Installer certificate, and notarization. None is bundled in this repository.

Mascot animations transform complete artwork, not independently rigged facial features. Snoozes are in-memory. Workout hours are configurable and saved locally; eye and stretch hours remain fixed.

Audio assets in `Assets/Sounds/` are original synthesized WAV files. Regenerate them with `python3 Scripts/generate-sounds.py`. Explicit sound previews play even when reminder sounds are muted; automatic cues respect mute.

## Windows

`Windows/` contains the native WPF app targeting .NET 10. It shares artwork and audio with macOS, and stores settings under `%LOCALAPPDATA%\Pippy`. The per-user Inno Setup installer includes the runtime and adds a Start menu shortcut.

On Windows with the .NET 10 SDK and Inno Setup 6:

```powershell
dotnet publish Windows/Pippy.csproj -c Release -r win-x64 --self-contained true -o dist/windows/publish
& dist/windows/publish/Pippy.exe --self-test
& dist/windows/publish/Pippy.exe --smoke-test previews
& "${env:ProgramFiles(x86)}/Inno Setup 6/ISCC.exe" Windows/installer.iss
```

The Windows GitHub Actions workflow builds the app, tests scheduling and persistence, decodes embedded assets, runs the actual 20-second countdown, renders the UI, and silently installs, tests, and uninstalls the package. It uploads the installer, checksum, and rendered previews as run artifacts. Manual dispatch can attach the installer to an existing release tag. The installer is not Authenticode signed.
