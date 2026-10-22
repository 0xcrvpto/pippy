#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
./Scripts/build.sh
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Packaging/Info.plist)
volume=Pippy
mount_point="/Volumes/$volume"
if [[ -e "$mount_point" ]]; then print -u2 "Eject the volume at $mount_point first."; exit 1; fi
# Stage outside Desktop/iCloud so Finder cannot attach metadata to the payload.
work_path=$(mktemp -d /private/tmp/pippy-dmg.XXXXXX)
device=''
cleanup() {
    [[ -n "$device" ]] && hdiutil detach "$device" -force -quiet 2>/dev/null || true
    /bin/rm -rf "$work_path"
}
trap cleanup EXIT
staging="$work_path/root"
mkdir -p "$staging/.background"
ditto --norsrc --noextattr dist/app.noindex/Pippy.app "$staging/Pippy.app"
ln -s /Applications "$staging/Applications"
cache_path="${TMPDIR:-/tmp}/pippy-swift-module-cache"
mkdir -p .build "$cache_path"
swiftc -module-cache-path "$cache_path" -parse-as-library -swift-version 5 -target arm64-apple-macosx13.0 -framework AppKit Scripts/dmg-background.swift -o .build/dmg-background
.build/dmg-background "$work_path"
tiffutil -cathidpicheck "$work_path/background.png" "$work_path/background@2x.png" -out "$staging/.background/background.tiff" >/dev/null
xattr -cr "$staging"
codesign --verify --strict "$staging/Pippy.app"

hdiutil create -quiet -volname "$volume" -srcfolder "$staging" -fs HFS+ -format UDRW -ov "$work_path/rw.dmg"
device=$(hdiutil attach -readwrite -noverify -noautoopen "$work_path/rw.dmg" | awk '/Apple_HFS/ {print $1}')
# Lay out the Finder window. The first run asks to let your terminal control Finder.
if ! osascript <<APPLESCRIPT
tell application "Finder"
    tell disk "$volume"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 800, 548}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 120
        set text size of viewOptions to 13
        set background picture of viewOptions to file ".background:background.tiff"
        set position of item "Pippy.app" of container window to {150, 190}
        set position of item "Applications" of container window to {450, 190}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
APPLESCRIPT
then
    print -u2 'Warning: Finder layout was not applied (automation denied?). The DMG still works, with a plain window.'
fi
# Finder's layout pass removes a pre-staged volume icon, so add it afterwards
# and mark the volume as having a custom icon (kHasCustomIcon in FinderInfo).
cp dist/app.noindex/Pippy.app/Contents/Resources/Pippy.icns "$mount_point/.VolumeIcon.icns"
xattr -wx com.apple.FinderInfo "0000000000000000040000000000000000000000000000000000000000000000" "$mount_point"
/bin/rm -rf "$mount_point/.fseventsd"
chmod -Rf go-w "$mount_point" || true
sync
# Forget the temporary mount so Spotlight and Launch Services don't list it as another Pippy.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$mount_point/Pippy.app" 2>/dev/null || true
hdiutil detach "$device" -quiet || { sleep 2; hdiutil detach "$device" -force -quiet; }
device=''
dmg="dist/Pippy-$version-arm64.dmg"
/bin/rm -f "$dmg"
hdiutil convert -quiet "$work_path/rw.dmg" -format UDZO -imagekey zlib-level=9 -o "$dmg"
hdiutil verify -quiet "$dmg"
(cd dist && shasum -a 256 Pippy-$version-arm64.* > SHA256SUMS.txt)
print "Disk image ready: $dmg"
