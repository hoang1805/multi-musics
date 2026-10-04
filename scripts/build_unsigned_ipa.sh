#!/usr/bin/env bash
# Builds an unsigned IPA (no Apple account needed). SideStore / Sideloadly
# re-sign it on install. Usage: scripts/build_unsigned_ipa.sh v0.1.0
set -euo pipefail
TAG="${1:?usage: build_unsigned_ipa.sh <tag>}"
VERSION="${TAG#v}"
BUILD_NUMBER="$(git rev-list --count HEAD)"
flutter pub get
dart run build_runner build -d
flutter test --exclude-tags live
flutter build ios --release --no-codesign --build-name="$VERSION" --build-number="$BUILD_NUMBER"
rm -rf build/ipa && mkdir -p build/ipa/Payload
cp -R build/ios/iphoneos/Runner.app build/ipa/Payload/
(cd build/ipa && zip -qr "multi-musics-$TAG.ipa" Payload)
echo "IPA: build/ipa/multi-musics-$TAG.ipa"
