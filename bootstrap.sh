#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOST=""
FRESH=0
ASSUME_YES=0

log() {
  printf '[bootstrap] %s\n' "$*"
}

die() {
  printf '[bootstrap] error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
usage: ./bootstrap.sh --fresh --host <macbook|ubuntu> [--yes]

Destructively replaces this repository's old dotfiles/tooling with the selected
Nix configuration. The cleanup is deliberately limited to the paths printed
before confirmation.

  --fresh          required acknowledgement of the one-way migration
  --host HOST      macbook (Apple Silicon macOS) or ubuntu (x86_64 Ubuntu)
  --yes             skip the interactive confirmation (for disposable VMs)
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --fresh)
        FRESH=1
        shift
        ;;
      --host)
        [[ $# -ge 2 ]] || die "--host requires a value"
        HOST="$2"
        shift 2
        ;;
      --yes)
        ASSUME_YES=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "unknown argument: $1"
        ;;
    esac
  done

  [[ "$FRESH" -eq 1 ]] || die "--fresh is required"
  case "$HOST" in
    macbook|ubuntu) ;;
    "") die "--host is required" ;;
    *) die "unknown host '$HOST' (expected macbook or ubuntu)" ;;
  esac
}

validate_home() {
  [[ -n "${HOME:-}" ]] || die "HOME is empty"
  [[ "$HOME" = /* ]] || die "HOME must be an absolute path"
  [[ "$HOME" != "/" ]] || die "refusing to use / as HOME"
}

ensure_not_root() {
  [[ "$(id -u)" -ne 0 ]] || die "do not run this script as root"
}

ensure_platform_matches_host() {
  local kernel arch ubuntu_id
  kernel="$(uname -s)"
  arch="$(uname -m)"

  case "$HOST:$kernel:$arch" in
    macbook:Darwin:arm64) ;;
    ubuntu:Linux:x86_64)
      ubuntu_id="$(
        # shellcheck disable=SC1091
        . /etc/os-release 2>/dev/null && printf '%s' "${ID:-}"
      )"
      [[ "$ubuntu_id" == "ubuntu" ]] ||
        die "host ubuntu requires Ubuntu Linux (found ${ubuntu_id:-unknown})"
      ;;
    macbook:*)
      die "host macbook requires Apple Silicon macOS (found $kernel/$arch)"
      ;;
    ubuntu:*)
      die "host ubuntu requires x86_64 Ubuntu (found $kernel/$arch)"
      ;;
  esac
}

ensure_repo() {
  [[ -f "$REPO_ROOT/flake.nix" ]] ||
    die "flake.nix is missing from $REPO_ROOT"
  [[ -x "$REPO_ROOT/scripts/sync-tools" ]] ||
    die "scripts/sync-tools is missing or not executable"
}

# This is the complete destructive allowlist. Do not replace it with globs,
# discovery, or a broad parent directory.
managed_paths() {
  cat <<EOF
$HOME/.config/chezmoi
$HOME/.local/bin/chezmoi
$HOME/.local/share/chezmoi
$HOME/.local/share/zinit
$HOME/.nvm
$HOME/.rustup
$HOME/.cargo/env
$HOME/.cargo/bin/cargo
$HOME/.cargo/bin/cargo-clippy
$HOME/.cargo/bin/cargo-fmt
$HOME/.cargo/bin/cargo-miri
$HOME/.cargo/bin/clippy-driver
$HOME/.cargo/bin/rls
$HOME/.cargo/bin/rust-analyzer
$HOME/.cargo/bin/rust-gdb
$HOME/.cargo/bin/rust-gdbgui
$HOME/.cargo/bin/rust-lldb
$HOME/.cargo/bin/rustc
$HOME/.cargo/bin/rustdoc
$HOME/.cargo/bin/rustfmt
$HOME/.cargo/bin/rustup
$HOME/.cargo/bin/uv
$HOME/.cargo/bin/uvx
$HOME/.cargo/bin/uvw
$HOME/.tmux/plugins/tpm
$HOME/.tmux/plugins/tmux-continuum
$HOME/.tmux/plugins/tmux-resurrect
$HOME/.tmux/plugins/tmux-sensible
$HOME/.tmux/plugins/tmux-yank
$HOME/.local/bin/bat
$HOME/.local/bin/fd
$HOME/.local/bin/jj
$HOME/.local/bin/lf
$HOME/.local/bin/mise
$HOME/.local/bin/uv
$HOME/.local/bin/uvx
$HOME/.local/bin/uvw
$HOME/.zshrc
$HOME/.zshenv
$HOME/.p10k.zsh
$HOME/.tmux.conf
$HOME/.jjconfig.toml
$HOME/.psqlrc
$HOME/.config/dotfiles
$HOME/.config/zsh
$HOME/.config/ghostty
$HOME/.config/lf
$HOME/.pi/agent/extensions/dialog-mode.ts
$HOME/.pi/agent/extensions/interactive-shell.ts
$HOME/.pi/agent/settings.json
$HOME/Library/Application Support/Sublime Text/Packages/User/CSES C++.sublime-build
$HOME/Library/Application Support/Sublime Text/Packages/User/CSES Layout.sublime-commands
$HOME/Library/Application Support/Sublime Text/Packages/User/CSES Rust.sublime-build
$HOME/Library/Application Support/Sublime Text/Packages/User/Package Control.sublime-settings
$HOME/Library/Application Support/Sublime Text/Packages/User/cpp-cp-boiler.sublime-snippet
$HOME/Library/Application Support/Sublime Text/Packages/User/rust-cses.sublime-snippet
$HOME/Library/Application Support/Sublime Text/Packages/User/setup_cses_layout.py
EOF
}

assert_managed_path() {
  local path="$1"
  case "$path" in
    "$HOME"/*) ;;
    *) die "internal safety check rejected cleanup path: $path" ;;
  esac
  [[ "$path" != "$HOME" ]] ||
    die "internal safety check rejected HOME itself"
}

show_cleanup_plan() {
  local path found
  found=0
  log "managed paths that currently exist and will be removed:"
  while IFS= read -r path; do
    assert_managed_path "$path"
    if [[ -e "$path" || -L "$path" ]]; then
      printf '  - %s\n' "$path"
      found=1
    fi
  done < <(managed_paths)
  [[ "$found" -eq 1 ]] || printf '  (none)\n'

  cat <<EOF

Preserved by design:
  - $HOME/.zshrc.local
  - $HOME/.modal.toml and Modal environment credentials
  - $HOME/.pi authentication, sessions, and history
  - $HOME/.ssh and Git credentials/config
  - every unrelated file under $HOME
EOF
}

confirm_cleanup() {
  local answer expected
  [[ "$ASSUME_YES" -eq 1 ]] && return
  expected="fresh-$HOST"
  printf '\nType %s to continue: ' "$expected"
  IFS= read -r answer
  [[ "$answer" == "$expected" ]] || die "confirmation did not match; nothing changed"
}

remove_managed_paths() {
  local path
  while IFS= read -r path; do
    assert_managed_path "$path"
    if [[ -e "$path" || -L "$path" ]]; then
      log "removing $path"
      rm -rf -- "$path"
    fi
  done < <(managed_paths)
}

detect_unsupported_nix() {
  if [[ -x /nix/nix-installer && -f /nix/receipt.json ]]; then
    return
  fi

  if command -v nix >/dev/null 2>&1 || [[ -e /nix ]]; then
    die "an existing non-Determinate Nix installation was found; remove it explicitly before running this bootstrap"
  fi
}

ensure_sudo() {
  command -v sudo >/dev/null 2>&1 ||
    die "sudo is required for the system-level Nix installation"
  log "checking sudo access"
  if [[ "$ASSUME_YES" -eq 1 ]]; then
    sudo -n true ||
      die "--yes requires non-interactive sudo access"
  else
    sudo -v
  fi
}

ensure_ubuntu_prerequisites() {
  local missing
  [[ "$HOST" == "ubuntu" ]] || return 0

  missing=0
  command -v curl >/dev/null 2>&1 || missing=1
  command -v xz >/dev/null 2>&1 || missing=1
  [[ -r /etc/ssl/certs/ca-certificates.crt ]] || missing=1
  [[ "$missing" -eq 1 ]] || return 0

  log "installing Ubuntu prerequisites"
  sudo apt-get update
  sudo env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y ca-certificates curl xz-utils
}

load_nix() {
  local profile
  for profile in \
    /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
    /nix/var/nix/profiles/default/etc/profile.d/nix.sh; do
    if [[ -r "$profile" ]]; then
      # shellcheck disable=SC1090
      . "$profile"
      break
    fi
  done
  command -v nix >/dev/null 2>&1 ||
    die "Nix installation completed but nix is not available"
}

ensure_determinate_nix() {
  local nixd
  if [[ -x /nix/nix-installer && -f /nix/receipt.json ]]; then
    log "repairing the existing Determinate Nix installation"
    sudo /nix/nix-installer repair --no-confirm
    load_nix

    nixd="$(command -v determinate-nixd 2>/dev/null || true)"
    if [[ -n "$nixd" ]]; then
      log "upgrading Determinate Nix"
      sudo "$nixd" upgrade
    fi
    return
  fi

  command -v curl >/dev/null 2>&1 ||
    die "curl is required to download the Determinate Nix installer"

  log "installing Determinate Nix with the official installer"
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix |
    sh -s -- install --no-confirm
  load_nix
}

build_configuration() {
  case "$HOST" in
    macbook)
      log "building nix-darwin configuration macbook"
      nix build \
        "$REPO_ROOT#darwinConfigurations.macbook.system" \
        --no-link
      ;;
    ubuntu)
      log "building Home Manager configuration hx@ubuntu"
      nix build \
        "$REPO_ROOT#homeConfigurations.\"hx@ubuntu\".activationPackage" \
        --no-link
      ;;
  esac
}

apply_configuration() {
  local nix_bin
  case "$HOST" in
    macbook)
      log "switching nix-darwin configuration macbook"
      nix_bin="$(command -v nix)"
      sudo "$nix_bin" run "$REPO_ROOT#darwin-rebuild" -- \
        switch --flake "$REPO_ROOT#macbook"
      ;;
    ubuntu)
      log "switching Home Manager configuration hx@ubuntu"
      nix run "$REPO_ROOT#home-manager" -- \
        switch --flake "$REPO_ROOT#hx@ubuntu"
      ;;
  esac
}

load_activated_path() {
  local profile_bin username
  username="$(id -un)"

  for profile_bin in \
    "$HOME/.nix-profile/bin" \
    "/etc/profiles/per-user/$username/bin" \
    "/run/current-system/sw/bin"; do
    [[ -d "$profile_bin" ]] || continue
    case ":$PATH:" in
      *":$profile_bin:"*) ;;
      *) PATH="$profile_bin:$PATH" ;;
    esac
  done
  export PATH
  hash -r
}

set_ubuntu_login_shell() {
  local username zsh_path
  [[ "$HOST" == "ubuntu" ]] || return 0
  username="$(id -un)"

  for zsh_path in \
    "$HOME/.nix-profile/bin/zsh" \
    "/etc/profiles/per-user/$username/bin/zsh"; do
    [[ -x "$zsh_path" ]] && break
  done
  [[ -x "$zsh_path" ]] ||
    die "Home Manager switched, but its zsh executable was not found"

  if ! grep -Fqx "$zsh_path" /etc/shells; then
    log "adding Home Manager zsh to /etc/shells"
    printf '%s\n' "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  log "setting the Ubuntu login shell to $zsh_path"
  sudo chsh -s "$zsh_path" "$username" ||
    die "could not set the Ubuntu login shell"
}

main() {
  parse_args "$@"
  ensure_not_root
  validate_home
  ensure_platform_matches_host
  ensure_repo
  detect_unsupported_nix
  show_cleanup_plan
  confirm_cleanup
  ensure_sudo
  ensure_ubuntu_prerequisites
  ensure_determinate_nix
  build_configuration
  remove_managed_paths
  apply_configuration
  load_activated_path
  set_ubuntu_login_shell
  "$REPO_ROOT/scripts/sync-tools"
  log "complete; start a new login shell with: exec zsh -l"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
