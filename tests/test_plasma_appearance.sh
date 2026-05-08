#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_contains() {
  local file=$1
  local needle=$2
  grep -qF "$needle" "$file" || fail "expected [$file] to contain: $needle"
}

assert_file_exists() {
  local file=$1
  [ -f "$file" ] || fail "expected [$file] to exist"
}

assert_file_contains "$ROOT_DIR/scripts/lib/common.sh" "plasma_appearance|Orchis Light + 顶部 Dock 布局|off"
assert_file_contains "$ROOT_DIR/scripts/run.sh" 'source "$ROOT_DIR/scripts/steps/14_plasma_appearance.sh"'
assert_file_contains "$ROOT_DIR/scripts/run.sh" "step_14_plasma_appearance"
assert_file_exists "$ROOT_DIR/scripts/steps/14_plasma_appearance.sh"
assert_file_contains "$ROOT_DIR/scripts/steps/14_plasma_appearance.sh" 'is_feature_enabled "plasma_appearance"'
assert_file_contains "$ROOT_DIR/scripts/steps/14_plasma_appearance.sh" 'lookandfeeltool --apply com.github.vinceliuice.Orchis'
assert_file_contains "$ROOT_DIR/scripts/steps/14_plasma_appearance.sh" "org.kde.plasma.icontasks"
assert_file_contains "$ROOT_DIR/scripts/steps/14_plasma_appearance.sh" "org.kde.plasma.panelspacer"
assert_file_contains "$ROOT_DIR/scripts/steps/14_plasma_appearance.sh" "kubuntu-migrate-backup"

echo 'PASS: plasma appearance route'
