#!/bin/zsh
set -euo pipefail

# Ensure the project is up to date
xcodegen generate

version=$(grep "MARKETING_VERSION:" project.yml | head -n 1 | awk '{print $2}')
buildno=$(grep "CURRENT_PROJECT_VERSION:" project.yml | head -n 1 | awk '{print $2}')
distdir=dist
tmpdir=DerivedData/bin
mkdir -p $distdir/macos

#
# macOS app build
#

echo "Building macOS application..."
xcodebuild -scheme NXBootApp -configuration Release -destination "platform=macOS" -derivedDataPath DerivedData clean build
ditto DerivedData/Build/Products/Release/NXBoot.app "$distdir/macos/NXBoot.app"

#
# command line tool build (macOS)
#

echo "Building nxboot macOS tool..."
xcodebuild -scheme NXBootCmd -configuration Release -destination "platform=macOS" -derivedDataPath DerivedData clean build
install DerivedData/Build/Products/Release/nxboot "$distdir/macos/nxboot"

echo "All done, results are available at $distdir/"
