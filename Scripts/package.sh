#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
./Scripts/build.sh
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Packaging/Info.plist)
# Stage outside Desktop/iCloud so Finder cannot attach metadata to the payload.
work_path=$(mktemp -d /private/tmp/pippy-package.XXXXXX)
trap '/bin/rm -rf "$work_path"' EXIT
staging="$work_path/root"
mkdir -p "$staging/Applications"
ditto --norsrc --noextattr dist/app.noindex/Pippy.app "$staging/Applications/Pippy.app"
xattr -cr "$staging"
codesign --verify --strict "$staging/Applications/Pippy.app"
pkgbuild --analyze --root "$staging" .build/components.plist
python3 - <<'PY'
import plistlib
from pathlib import Path
p = Path('.build/components.plist')
data = plistlib.loads(p.read_bytes())
for component in data:
    component['BundleIsRelocatable'] = False
    component['BundleOverwriteAction'] = 'upgrade'
p.write_bytes(plistlib.dumps(data))
PY
pkgbuild --root "$staging" --component-plist .build/components.plist --identifier com.heycling.pip.installer --version "$version" --install-location / "$work_path/Pippy.pkg"
cp "$work_path/Pippy.pkg" "dist/Pippy-$version-arm64.pkg"
(cd dist && shasum -a 256 Pippy-$version-arm64.* > SHA256SUMS.txt)
print "Installer ready: dist/Pippy-$version-arm64.pkg"
