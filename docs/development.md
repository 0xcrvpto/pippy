# Development

The maintained project contains:

- `Sources/`: native AppKit app and reminder logic.
- `Assets/`: current app icon and three mascot images.
- `Packaging/Info.plist`: app metadata; the existing bundle identifier preserves local settings.
- `Scripts/`: reproducible build, icon, test, preview, and installer commands.
- `dist/`: generated installers, excluded from Git. The built app goes in `dist/app.noindex/Pippy.app`; the `.noindex` suffix keeps Spotlight from listing development builds as extra copies of Pippy.

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

The update check (`Sources/Updates.swift`) reads `releases/latest` from the GitHub API, ignores drafts and pre-releases, compares versions numerically, and links to the release asset ending in `-arm64.dmg` (falling back to the release page). Releases must therefore be published as regular, non-pre-release GitHub releases with a DMG named that way.

Mascot animations transform complete artwork, not independently rigged facial features. Snoozes are in-memory. Each buddy has its own active hours, saved locally (`hours.<kind>.start/end`, with Rally keeping `workout.startMinute/endMinute`).

Audio assets in `Assets/Sounds/` are original synthesized WAV files in five sets (`Blink*` is Soft Bells, plus `Marimba*`, `Chimes*`, `Kalimba*`, `Woodblock*`), each with start, halfway, complete, and preview cues. Regenerate them with `python3 Scripts/generate-sounds.py`; the `Blink*` files are unchanged byte for byte. Each buddy's set is saved under `sound.<kind>`. Explicit sound previews play even when reminder sounds are muted; automatic cues respect mute.
