#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
work_path=$(mktemp -d /private/tmp/pippy-build.XXXXXX)
trap '/bin/rm -rf "$work_path"' EXIT
app_path="$work_path/Pippy.app"
cache_path="${TMPDIR:-/tmp}/pippy-swift-module-cache"
mkdir -p .build "$cache_path" "$app_path/Contents/MacOS" "$app_path/Contents/Resources"
swiftc -module-cache-path "$cache_path" -parse-as-library -swift-version 5 -target arm64-apple-macosx13.0 -framework AppKit -framework QuartzCore Sources/*.swift -o .build/Pippy
cp .build/Pippy "$app_path/Contents/MacOS/Pippy"
cp Packaging/Info.plist "$app_path/Contents/Info.plist"
cp Assets/*.png "$app_path/Contents/Resources/"
mkdir -p "$app_path/Contents/Resources/Sounds"
cp Assets/Sounds/*.wav "$app_path/Contents/Resources/Sounds/"
python3 Scripts/package-icon.py "$app_path/Contents/Resources/Pippy.icns"
# Remove Finder metadata from generated output before sealing the bundle.
xattr -cr "$app_path"
# Ad-hoc signing seals the bundle but is not Developer ID signing or notarization.
codesign --force --sign - "$app_path"
codesign --verify --strict "$app_path"
# Spotlight skips folders ending in .noindex, so dev builds don't show up as extra apps.
app_dir=dist/app.noindex
mkdir -p "$app_dir"
# Replace only this script's generated app output (and the pre-.noindex location).
for old in "$app_dir/Pippy.app" dist/Pippy.app; do if [[ -d "$old" ]]; then /bin/rm -rf "$old"; fi; done
ditto --norsrc --noextattr "$app_path" "$app_dir/Pippy.app"
print "Built $app_dir/Pippy.app"
