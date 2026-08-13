#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES="$REPO_ROOT/tests/fixtures/mise"

command -v mise >/dev/null 2>&1 || {
  printf 'mise is unavailable; apply the Nix configuration first\n' >&2
  exit 1
}

export MISE_YES=1

node_result="$(
  cd "$FIXTURES/node"
  mise exec -- node smoke.js
)"
[[ "$node_result" == "node-ok" ]]

go_result="$(
  cd "$FIXTURES/go"
  mise exec -- go run .
)"
[[ "$go_result" == "go-ok" ]]

rust_result="$(
  cd "$FIXTURES/rust"
  mise exec -- cargo run --quiet
)"
[[ "$rust_result" == "rust-ok" ]]

printf 'mise fixture projects passed\n'
