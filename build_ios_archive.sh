#!/bin/bash

# iOS Archive Build Script
# This script builds the iOS app archive without running pod install
# to bypass the CocoaPods 1.16.2 compatibility issue

set -e

echo "🚀 Building iOS Archive for App Store..."

# Navigate to project root
cd "$(dirname "$0")"

# Set build configuration
CONFIGURATION="Release"
SCHEME="Runner"
WORKSPACE="ios/Runner.xcworkspace"
ARCHIVE_PATH="build/ios/Runner.xcarchive"
EXPORT_PATH="build/ios/ipa"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/ios/Runner.xcarchive
rm -rf build/ios/ipa
mkdir -p build/ios

# Build archive
echo "📦 Creating archive..."
xcodebuild archive \
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates

# Check if archive was created
if [ -d "$ARCHIVE_PATH" ]; then
  echo "✅ Archive created successfully at: $ARCHIVE_PATH"
  echo ""
  echo "📤 Next steps:"
  echo "1. Open Xcode Organizer: Window → Organizer"
  echo "2. Select the archive and click 'Distribute App'"
  echo "3. Choose 'App Store Connect' and follow the prompts"
  echo ""
  echo "Or run this command to export:"
  echo "  xcodebuild -exportArchive -archivePath $ARCHIVE_PATH -exportPath $EXPORT_PATH -exportOptionsPlist ios/ExportOptions.plist"
else
  echo "❌ Archive creation failed"
  exit 1
fi
