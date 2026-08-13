#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

pass_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'ok %d - %s\n' "$pass_count" "$1"
}

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

assert_exists() {
  [[ -e "$1" || -L "$1" ]] || fail "expected $1 to exist"
}

assert_missing() {
  [[ ! -e "$1" && ! -L "$1" ]] || fail "expected $1 to be absent"
}

bash -n \
  "$REPO_ROOT/bootstrap.sh" \
  "$REPO_ROOT/scripts/sync-tools" \
  "$REPO_ROOT/tests/smoke.sh" \
  "$REPO_ROOT/tests/mise-smoke.sh" \
  "$REPO_ROOT/tests/fixtures/bin/mise" \
  "$REPO_ROOT/tests/fixtures/bin/uv"
pass "shell scripts parse"

HOME="$TEST_ROOT/home"
export HOME
mkdir -p "$HOME"

# shellcheck disable=SC1091
. "$REPO_ROOT/bootstrap.sh"

FRESH=0
HOST=""
ASSUME_YES=0
parse_args --fresh --host ubuntu --yes
[[ "$FRESH" -eq 1 && "$HOST" == "ubuntu" && "$ASSUME_YES" -eq 1 ]] ||
  fail "valid arguments were not parsed"
pass "fresh host arguments parse"

mkdir -p "$HOME/.nix-profile/bin"
original_path="$PATH"
load_activated_path
case ":$PATH:" in
  *":$HOME/.nix-profile/bin:"*) ;;
  *) fail "activated Home Manager profile was not added to PATH" ;;
esac
PATH="$original_path"
export PATH
pass "activated profile is available to post-switch tool sync"

HOST="macbook"
ensure_ubuntu_prerequisites ||
  fail "non-Ubuntu prerequisite check should be a successful no-op"
set_ubuntu_login_shell ||
  fail "non-Ubuntu login-shell setup should be a successful no-op"
HOST="ubuntu"
pass "platform-specific no-op branches succeed under set -e"

if (FRESH=0; HOST=""; ASSUME_YES=0; parse_args --host ubuntu) 2>/dev/null; then
  fail "--fresh should be mandatory"
fi
if (FRESH=0; HOST=""; ASSUME_YES=0; parse_args --fresh --host mystery) 2>/dev/null; then
  fail "unknown hosts should fail"
fi
pass "unsafe bootstrap arguments fail"

mkdir -p \
  "$HOME/.config/dotfiles" \
  "$HOME/.config/zsh" \
  "$HOME/.nvm" \
  "$HOME/.tmux/plugins/tpm" \
  "$HOME/.pi/agent/extensions" \
  "$HOME/.pi/agent/sessions" \
  "$HOME/.ssh" \
  "$HOME/.config/unrelated"
touch \
  "$HOME/.zshrc" \
  "$HOME/.zshenv" \
  "$HOME/.config/zsh/.zshrc" \
  "$HOME/.config/dotfiles/owned" \
  "$HOME/.nvm/nvm.sh" \
  "$HOME/.tmux/plugins/tpm/owned" \
  "$HOME/.pi/agent/extensions/dialog-mode.ts" \
  "$HOME/.pi/agent/settings.json"
ln -s "$HOME/does-not-exist" "$HOME/.local-bin-placeholder"

# Authentication and unrelated state are deliberately outside the allowlist.
touch \
  "$HOME/.zshrc.local" \
  "$HOME/.modal.toml" \
  "$HOME/.pi/auth.json" \
  "$HOME/.pi/agent/sessions/keep" \
  "$HOME/.ssh/id_ed25519" \
  "$HOME/.gitconfig" \
  "$HOME/.config/unrelated/keep"

plan="$(show_cleanup_plan)"
case "$plan" in
  *"$HOME/.zshrc"*) ;;
  *) fail "cleanup plan did not show the seeded zshrc" ;;
esac
case "$plan" in
  *"$HOME/.nvm"*) ;;
  *) fail "cleanup plan did not show seeded managed paths" ;;
esac
pass "cleanup plan is inspectable"

remove_managed_paths >/dev/null
assert_missing "$HOME/.zshrc"
assert_missing "$HOME/.zshenv"
assert_missing "$HOME/.config/dotfiles"
assert_missing "$HOME/.config/zsh"
assert_missing "$HOME/.nvm"
assert_missing "$HOME/.tmux/plugins/tpm"
assert_missing "$HOME/.pi/agent/extensions/dialog-mode.ts"
assert_missing "$HOME/.pi/agent/settings.json"
pass "cleanup removes managed legacy state"

assert_exists "$HOME/.zshrc.local"
assert_exists "$HOME/.modal.toml"
assert_exists "$HOME/.pi/auth.json"
assert_exists "$HOME/.pi/agent/sessions/keep"
assert_exists "$HOME/.ssh/id_ed25519"
assert_exists "$HOME/.gitconfig"
assert_exists "$HOME/.config/unrelated/keep"
pass "cleanup preserves auth and unrelated state"

if (assert_managed_path "$TEST_ROOT/outside") 2>/dev/null; then
  fail "cleanup safety check accepted a path outside HOME"
fi
pass "cleanup rejects paths outside HOME"

line_count="$(
  awk -F '\t' '
    $0 !~ /^#/ && NF {
      if (NF != 2 || $1 == "" || $2 == "") exit 2
      count++
    }
    END { print count + 0 }
  ' "$REPO_ROOT/scripts/skills.tsv"
)"
[[ "$line_count" -eq 3 ]] || fail "expected three explicit skills"
pass "skills manifest is well formed"

tool_home="$TEST_ROOT/tool-home"
tool_log="$TEST_ROOT/tool.log"
mkdir -p "$tool_home"
PATH="$REPO_ROOT/tests/fixtures/bin:$PATH" \
  HOME="$tool_home" \
  TOOL_LOG="$tool_log" \
  bash "$REPO_ROOT/scripts/sync-tools" >/dev/null

grep -Fqx $'mise\tinstall\tnode@lts\tgo@latest\trust@stable' "$tool_log" ||
  fail "sync-tools did not request the intended mise runtimes"
grep -Fqx $'mise\texec\tnode@lts\t--\tnpm\tinstall\t--global\t@earendil-works/pi-coding-agent' "$tool_log" ||
  fail "sync-tools did not install Pi through mise Node LTS"
grep -Fqx $'uv\tpython\tinstall\t3.13' "$tool_log" ||
  fail "sync-tools did not request uv-managed Python 3.13"
grep -Fqx $'uv\ttool\tinstall\t--upgrade\t--python\t3.13\t--managed-python\tmodal@latest' "$tool_log" ||
  fail "sync-tools did not install Modal through uv"
skill_call_count="$(
  grep -Fc $'mise\texec\tnode@lts\t--\tnpx\t--yes\tskills\tadd\t' "$tool_log"
)"
[[ "$skill_call_count" -eq 3 ]] ||
  fail "sync-tools did not apply every skill manifest entry"
pass "tool sync uses the intended ownership boundaries"

printf '1..%d\n' "$pass_count"
