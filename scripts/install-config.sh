#!/usr/bin/env bash
set -euo pipefail

config_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$config_dir"

if command -v brew >/dev/null 2>&1; then
  node24_prefix=$(brew --prefix node@24 2>/dev/null || true)
  if [[ -n "$node24_prefix" ]]; then
    export PATH="$node24_prefix/bin:$PATH"
  fi
fi

expected_pi=$(node -p "require('./versions.json').pi")
expected_node=$(node -p "require('./versions.json').node")
package_source=$(node -p "require('./versions.json').packages['pi-sessions'].source")
expected_package=$(node -p "require('./versions.json').packages['pi-sessions'].version")

if [[ "$(node --version)" != "v$expected_node" ]]; then
  echo "Install Node $expected_node before applying this configuration." >&2
  exit 1
fi
if [[ "$(pi --version)" != "$expected_pi" ]]; then
  echo "Install Pi $expected_pi before applying this configuration." >&2
  exit 1
fi

installed_package=""
if [[ -f "$config_dir/npm/node_modules/pi-sessions/package.json" ]]; then
  installed_package=$(node -p "require('$config_dir/npm/node_modules/pi-sessions/package.json').version")
fi
if [[ "$installed_package" != "$expected_package" ]]; then
  pi install "$package_source"
fi

launch_target="$config_dir/npm/node_modules/pi-sessions/extensions/subagents/launch-target.ts"
if grep -Fq 'approveProjectTrust: false' "$launch_target"; then
  :
elif grep -Fq 'approveProjectTrust: true' "$launch_target"; then
  git apply patches/pi-sessions-0.12.1-noninteractive-trust.patch
else
  echo "The pi-sessions launch target no longer matches the reviewed patch." >&2
  exit 1
fi

exec scripts/verify-config.sh
