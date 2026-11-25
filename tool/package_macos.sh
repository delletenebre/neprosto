#!/bin/sh
set -eu

project_dir=$(cd "$(dirname "$0")/.." && pwd)
app=${1:-"$project_dir/build/macos/Build/Products/Release/NeProSto.app"}
version=$(plutil -extract CFBundleShortVersionString raw "$app/Contents/Info.plist")
codesign --verify --deep --strict "$app"

output_dir="$project_dir/build/release"
image="NeProSto-$version-macOS.dmg"
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
mkdir -p "$temp_dir/volume" "$output_dir"
ditto "$app" "$temp_dir/volume/NeProSto.app"
ln -s /Applications "$temp_dir/volume/Applications"
hdiutil create -volname NeProSto -fs HFS+ -format UDZO \
  -srcfolder "$temp_dir/volume" "$temp_dir/$image"
hdiutil verify "$temp_dir/$image"
mv -f "$temp_dir/$image" "$output_dir/$image"
echo "$output_dir/$image"
