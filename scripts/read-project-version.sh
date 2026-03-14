#!/usr/bin/env bash

set -euo pipefail

scheme="${SCHEME:-Emus}"
configuration="${CONFIGURATION:-Release}"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
derived_data_path="$(mktemp -d "${TMPDIR:-/tmp}/emus-build-settings.XXXXXX")"

cleanup() {
  rm -rf "$derived_data_path"
}

trap cleanup EXIT

build_settings="$(
  cd "$root_dir"
  xcodebuild \
    -project Emus.xcodeproj \
    -scheme "$scheme" \
    -configuration "$configuration" \
    -derivedDataPath "$derived_data_path" \
    -showBuildSettings \
    2>/dev/null
)"

marketing_version="$(
  printf '%s\n' "$build_settings" \
    | sed -n 's/^[[:space:]]*MARKETING_VERSION = //p' \
    | head -n 1
)"
current_project_version="$(
  printf '%s\n' "$build_settings" \
    | sed -n 's/^[[:space:]]*CURRENT_PROJECT_VERSION = //p' \
    | head -n 1
)"

if [[ -z "$marketing_version" || -z "$current_project_version" ]]; then
  echo "Failed to read project version from Xcode build settings." >&2
  exit 1
fi

release_tag="v$marketing_version"

if [[ "${1:-}" == "--github-env" ]]; then
  printf 'MARKETING_VERSION=%s\n' "$marketing_version"
  printf 'CURRENT_PROJECT_VERSION=%s\n' "$current_project_version"
  printf 'RELEASE_TAG=%s\n' "$release_tag"
  exit 0
fi

printf 'MARKETING_VERSION=%s\n' "$marketing_version"
printf 'CURRENT_PROJECT_VERSION=%s\n' "$current_project_version"
printf 'RELEASE_TAG=%s\n' "$release_tag"
