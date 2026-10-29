#!/usr/bin/env bash
set -euo pipefail

plugin_dir="$(cd "$(dirname "$0")/.." && pwd)"
smoke_dir="$(mktemp -d "${TMPDIR:-/tmp}/mise-raku-smoke.XXXXXX")"
# Retain the sandbox for inspection; it never touches the user's mise installs.
echo "Smoke test directory: $smoke_dir"
export MISE_CONFIG_DIR="$smoke_dir/config"
export MISE_DATA_DIR="$smoke_dir/data"
export MISE_CACHE_DIR="$smoke_dir/cache"
export MISE_STATE_DIR="$smoke_dir/state"
export MISE_GLOBAL_CONFIG_FILE="$smoke_dir/config/config.toml"
export MISE_SYSTEM_CONFIG_FILE="$smoke_dir/system.toml"
export MISE_YES=1
mkdir -p "$smoke_dir/project"
cd "$smoke_dir/project"
mise plugins link raku "$plugin_dir"
mise ls-remote raku
mise use "raku@${1:-2026.09}"
mise exec "raku@${1:-2026.09}" -- raku --version
mise exec "raku@${1:-2026.09}" -- raku -e 'die "Raku assertion failed" unless (20 + 22) == 42; say "Raku smoke test passed"'
mise exec "raku@${1:-2026.09}" -- zef --version
