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

The check runs a full eye-break countdown and verifies cue order and snooze actions. The preview renders each card. Packaging compiles for Apple silicon, generates the icon with Apple's iconutil, ad-hoc signs and verifies the app, and builds an installer targeting `/Applications/Pippy.app`.

The installer disables bundle relocation so it does not overwrite a Desktop development copy. It has no install scripts and does not launch the app or change login items. Outputs include a SHA-256 checksum.

Ad-hoc signing is not Developer ID signing. Public friction-free distribution requires an Apple Developer ID Application certificate, a Developer ID Installer certificate, and notarization. None is bundled in this repository.

Mascot animations transform complete artwork, not independently rigged facial features. Snoozes are in-memory. Working hours are currently fixed.
