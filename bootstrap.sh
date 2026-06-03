#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEZMOI_BIN="${CHEZMOI_BIN:-$HOME/.local/bin/chezmoi}"
PROFILES="${DOTFILES_PROFILES:-core,dev,ai}"

log() { printf '[dotfiles] %s\n' "$*"; }
err() { printf '[dotfiles] error: %s\n' "$*" >&2; }

ensure_not_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    err "do not run bootstrap as root"
    exit 1
  fi
}

path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

install_chezmoi() {
  if command -v chezmoi >/dev/null 2>&1; then
    CHEZMOI_BIN="$(command -v chezmoi)"
    return
  fi

  if [[ -x "$CHEZMOI_BIN" ]]; then
    return
  fi

  log "installing chezmoi to $HOME/.local/bin"
  mkdir -p "$HOME/.local/bin"
  path_prepend "$HOME/.local/bin"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
}

apply_dotfiles() {
  log "applying chezmoi source: $DOTFILES_DIR/home"
  "$CHEZMOI_BIN" apply --source "$DOTFILES_DIR/home"
}

install_packages() {
  if [[ "${DOTFILES_SKIP_PACKAGES:-0}" == "1" ]]; then
    log "skipping package installation"
    return
  fi

  log "installing package profiles: $PROFILES"
  "$DOTFILES_DIR/scripts/install-packages" --profiles "$PROFILES"
}

install_skills() {
  if [[ "${DOTFILES_SKIP_SKILLS:-0}" == "1" ]]; then
    log "skipping skill installation"
    return
  fi

  "$DOTFILES_DIR/scripts/install-skills"
}

main() {
  ensure_not_root
  install_chezmoi
  apply_dotfiles
  install_packages
  install_skills
  log "done. restart your shell or run: exec zsh -l"
}

main "$@"
