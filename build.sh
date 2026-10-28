#!/bin/zsh
set -euo pipefail
cd "${0:A:h}"
APP_PATH="${APP_PATH:-/Applications/Public IP.app}"
BUILD_ARCH="$(uname -m)"
mkdir -p build "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
xcrun swiftc -O -target "${BUILD_ARCH}-apple-macosx13.0" Sources/IPAddress.swift Sources/LaunchAtLogin.swift Sources/AppDelegate.swift Sources/main.swift -o "$APP_PATH/Contents/MacOS/PublicIP" -framework AppKit -framework Network -framework ServiceManagement
cat > "$APP_PATH/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>PublicIP</string>
<key>CFBundleIdentifier</key><string>local.publicip.menu</string>
<key>CFBundleName</key><string>Public IP</string>
<key>CFBundleDisplayName</key><string>Public IP</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.1.1</string>
<key>CFBundleVersion</key><string>4</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleLocalizations</key><array><string>en</string></array>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --sign - "$APP_PATH"
print "Built: $APP_PATH"
