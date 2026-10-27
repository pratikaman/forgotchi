#!/bin/sh
# Builds Forgotchi.app next to this script.
set -e
cd "$(dirname "$0")"
mkdir -p Forgotchi.app/Contents/MacOS
# Pin the deployment target: some toolchains default to a newer macOS than the one installed, and the app then won't launch (-10825).
swiftc -O -target "$(uname -m)-apple-macos14.0" main.swift -o Forgotchi.app/Contents/MacOS/Forgotchi
cat > Forgotchi.app/Contents/Info.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>Forgotchi</string>
  <key>CFBundleIdentifier</key><string>com.pratikaman.forgotchi</string>
  <key>CFBundleName</key><string>Forgotchi</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign -s - --force Forgotchi.app
