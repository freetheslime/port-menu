#!/bin/zsh
#
# Builds a standalone "Port Menu.app" bundle using only the Swift toolchain
# (no Xcode / xcodebuild required). Output goes to dist/Port Menu.app.
#
# Usage:
#   scripts/build-app.sh                # release build
#   CONFIGURATION=Debug scripts/build-app.sh
#
# Sparkle auto-update is unavailable in this build (it is wired up only when
# building through the Xcode project). Everything else works identically.

set -euo pipefail

cd "$(dirname "$0")/.."

CONFIGURATION="${CONFIGURATION:-Release}"
APP_NAME="Port Menu"
EXEC_NAME="porter"            # SPM executable product name
BUNDLE_ID="eduard.Porter"
VERSION="${VERSION:-0.1.0}"
BUILD="${BUILD:-1}"

SWIFT_FLAG="release"
[[ "$CONFIGURATION" == "Debug" ]] && SWIFT_FLAG="debug"

DIST="dist"
APP_DIR="${DIST}/${APP_NAME}.app"

echo "Building (${CONFIGURATION})..."
swift build -c "$SWIFT_FLAG"

BIN_PATH=".build/${SWIFT_FLAG}/${EXEC_NAME}"
if [[ ! -f "$BIN_PATH" ]]; then
  echo "error: expected binary at $BIN_PATH" >&2
  exit 1
fi

echo "Assembling ${APP_DIR}..."
rm -rf "$APP_DIR"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# Executable (rename to app display name)
cp "$BIN_PATH" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_DIR}/Contents/MacOS/${APP_NAME}"

# Icon
cp Porter/AppIconSource.icns "${APP_DIR}/Contents/Resources/AppIcon.icns"

# PkgInfo
printf 'APPL????' > "${APP_DIR}/Contents/PkgInfo"

# Info.plist
cat > "${APP_DIR}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>${APP_NAME}</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>${BUNDLE_ID}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>${APP_NAME}</string>
	<key>CFBundleDisplayName</key>
	<string>${APP_NAME}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>${VERSION}</string>
	<key>CFBundleVersion</key>
	<string>${BUILD}</string>
	<key>LSApplicationCategoryType</key>
	<string>public.app-category.developer-tools</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST

# Register the bundle with Launch Services so Finder / Spotlight pick it up
echo "Registering with Launch Services..."
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister \
  -f "$APP_DIR" >/dev/null 2>&1 || true

echo
echo "Done. App is at: ${APP_DIR}"
echo "Open it with: open \"${APP_DIR}\""
