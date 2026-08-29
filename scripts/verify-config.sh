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
expected_npm=$(node -p "require('./versions.json').npm")
expected_source=$(node -p "require('./versions.json').packages['pi-sessions'].source")
expected_package=$(node -p "require('./versions.json').packages['pi-sessions'].version")
expected_integrity=$(node -p "require('./versions.json').packages['pi-sessions'].integrity")

actual_pi=$(pi --version)
actual_node=$(node --version)
actual_npm=$(npm --version)
if [[ "$actual_pi" != "$expected_pi" ]]; then
  echo "Pi version mismatch: expected $expected_pi, found $actual_pi" >&2
  exit 1
fi
if [[ "$actual_node" != "v$expected_node" ]]; then
  echo "Node version mismatch: expected $expected_node, found $actual_node" >&2
  exit 1
fi
if [[ "$actual_npm" != "$expected_npm" ]]; then
  echo "npm version mismatch: expected $expected_npm, found $actual_npm" >&2
  exit 1
fi

configured_source=$(node -p "require('./settings.json').packages.find(value => typeof value === 'string' && value.startsWith('npm:pi-sessions')) || ''")
if [[ "$configured_source" != "$expected_source" ]]; then
  echo "pi-sessions source mismatch: expected $expected_source, found $configured_source" >&2
  exit 1
fi

package_file="$config_dir/npm/node_modules/pi-sessions/package.json"
lock_file="$config_dir/npm/package-lock.json"
if [[ ! -f "$package_file" || ! -f "$lock_file" ]]; then
  echo "pi-sessions is not installed; run scripts/install-config.sh" >&2
  exit 1
fi

actual_package=$(node -p "require('$package_file').version")
actual_integrity=$(node -p "require('$lock_file').packages['node_modules/pi-sessions'].integrity")
if [[ "$actual_package" != "$expected_package" ]]; then
  echo "pi-sessions version mismatch: expected $expected_package, found $actual_package" >&2
  exit 1
fi
if [[ "$actual_integrity" != "$expected_integrity" ]]; then
  echo "pi-sessions integrity mismatch" >&2
  exit 1
fi

launch_target="$config_dir/npm/node_modules/pi-sessions/extensions/subagents/launch-target.ts"
if ! grep -Fq 'approveProjectTrust: false' "$launch_target"; then
  echo "pi-sessions trust-hardening patch is not applied" >&2
  exit 1
fi

for required in SYSTEM.md APPEND_SYSTEM.md extensions/herdr-agent-state.ts extensions/noninteractive-project-trust.ts; do
  if [[ ! -f "$config_dir/$required" ]]; then
    echo "Missing required configuration: $required" >&2
    exit 1
  fi
done

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  for private_path in auth.json trust.json models-store.json sessions pi-sessions npm backups; do
    if git ls-files --error-unmatch "$private_path" >/dev/null 2>&1 || git ls-files "$private_path/**" | grep -q .; then
      echo "Sensitive or generated path is tracked: $private_path" >&2
      exit 1
    fi
  done
fi

rpc_state=$(printf '%s\n' '{"type":"get_state"}' | pi --mode rpc --no-session)
printf '%s\n' "$rpc_state" | node -e '
let input = "";
process.stdin.on("data", chunk => input += chunk);
process.stdin.on("end", () => {
  const response = JSON.parse(input.trim().split("\n").at(-1));
  if (!response.success || !response.data?.model?.id) process.exit(1);
  console.log(`Verified Pi ${response.data.model.id} startup with pinned configuration.`);
});
'
