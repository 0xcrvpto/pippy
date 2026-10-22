#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
app_path="$PWD/dist/Pippy.app"
cache_path="${TMPDIR:-/tmp}/pippy-swift-module-cache"
mkdir -p .build "$cache_path" "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
swiftc -module-cache-path "$cache_path" -parse-as-library -swift-version 5 -target arm64-apple-macosx13.0 -framework AppKit -framework QuartzCore Sources/*.swift -o .build/Pippy
cp .build/Pippy "$app_path/Contents/MacOS/Pippy"
cp Packaging/Info.plist "$app_path/Contents/Info.plist"
cp Assets/*.png "$app_path/Contents/Resources/"
python3 Scripts/package-icon.py
# Remove Finder metadata from generated output before sealing the bundle.
xattr -cr "$app_path"
# Ad-hoc signing seals the bundle but is not Developer ID signing or notarization.
codesign --force --sign - "$app_path"
codesign --verify --strict "$app_path"
print 'Built dist/Pippy.app'
