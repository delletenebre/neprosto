#!/bin/sh
set -eu

project_dir=$(cd "$(dirname "$0")/.." && pwd)
app=${1:-"$project_dir/build/macos/Build/Products/Release/NeProSto.app"}
version=$(plutil -extract CFBundleShortVersionString raw "$app/Contents/Info.plist")
identity=${MACOS_SIGN_IDENTITY:-}
if [ -n "$identity" ]; then
  : "${APPLE_NOTARY_ID:?Set the Apple Account email for notarization}"
  : "${APPLE_NOTARY_PASSWORD:?Set the app-specific password for notarization}"
fi

output_dir="$project_dir/build/release"
image="NeProSto-$version-macOS.dmg"
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
mkdir -p "$temp_dir/volume" "$output_dir"
staged_app="$temp_dir/volume/NeProSto.app"
ditto "$app" "$staged_app"
if [ -n "$identity" ]; then
  # Flutter embeds the engine, Dart AOT code and native assets as frameworks.
  for framework in "$staged_app"/Contents/Frameworks/*.framework; do
    codesign --force --sign "$identity" --options runtime --timestamp "$framework"
  done
  codesign --force --sign "$identity" --options runtime --timestamp \
    --entitlements "$project_dir/macos/Runner/Release.entitlements" "$staged_app"
fi
codesign --verify --deep --strict "$staged_app"
ln -s /Applications "$temp_dir/volume/Applications"
hdiutil create -volname NeProSto -fs HFS+ -format UDZO \
  -srcfolder "$temp_dir/volume" "$temp_dir/$image"
hdiutil verify "$temp_dir/$image"
if [ -n "$identity" ]; then
  bundle_id=$(plutil -extract CFBundleIdentifier raw "$staged_app/Contents/Info.plist")
  team_id=$(codesign -dv "$staged_app" 2>&1 | sed -n 's/^TeamIdentifier=//p')
  codesign --sign "$identity" --timestamp --identifier "$bundle_id.dmg" "$temp_dir/$image"
  # Reuse the same credentials when retrieving Apple's diagnostic log.
  set -- --apple-id "$APPLE_NOTARY_ID" --team-id "$team_id" --password "$APPLE_NOTARY_PASSWORD"
  result="$temp_dir/notarization.json"
  if ! xcrun notarytool submit "$temp_dir/$image" "$@" --wait --output-format json > "$result" ||
     [ "$(plutil -extract status raw "$result" 2>/dev/null)" != "Accepted" ]; then
    echo "Apple notarization did not complete successfully." >&2
    if submission_id=$(plutil -extract id raw "$result" 2>/dev/null); then
      xcrun notarytool log "$submission_id" "$@" >&2
    fi
    exit 1
  fi
  xcrun stapler staple "$temp_dir/$image"
  xcrun stapler validate "$temp_dir/$image"
fi
mv -f "$temp_dir/$image" "$output_dir/$image"
echo "$output_dir/$image"
