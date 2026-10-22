#!/bin/zsh
set -euo pipefail
cd "${0:A:h}/.."
cache_path="${TMPDIR:-/tmp}/pippy-swift-module-cache"
mkdir -p .build "$cache_path"
swiftc -module-cache-path "$cache_path" -D PREVIEW_RENDERER -parse-as-library -swift-version 5 -target arm64-apple-macosx13.0 -framework AppKit -framework QuartzCore Sources/*.swift Scripts/check-reminders.swift -o .build/check-reminders
.build/check-reminders
