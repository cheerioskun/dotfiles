#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '[dotfiles] %s\n' "$*"; }

if [[ "$(id -u)" -eq 0 ]]; then
  echo "do not run bootstrap as root" >&2
  exit 1
fi

case "$(uname -s)" in
  Linux)  "$DOTFILES_DIR/scripts/linux" ;;
  Darwin) "$DOTFILES_DIR/scripts/macos" ;;
  *) echo "unsupported operating system: $(uname -s)" >&2; exit 1 ;;
esac

export PATH="$HOME/.local/bin:$PATH"

if ! command -v chezmoi >/dev/null 2>&1; then
  log "installing chezmoi"
  mkdir -p "$HOME/.local/bin"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi

# Docker installs tools in a cached layer before copying the configs.
if [[ "${DOTFILES_SKIP_CONFIGS:-0}" != 1 ]]; then
  log "applying configs"
  chezmoi apply --source "$DOTFILES_DIR/home"
fi

if [[ ! -d "$HOME/.local/share/zinit/zinit.git" ]]; then
  log "installing zinit"
  git clone https://github.com/zdharma-continuum/zinit.git \
    "$HOME/.local/share/zinit/zinit.git"
fi

if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  log "installing tmux plugin manager"
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  log "installing nvm"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh |
    PROFILE=/dev/null bash
fi
# shellcheck disable=SC1090
source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm alias default 'lts/*'

if [[ ! -s "$HOME/.gvm/scripts/gvm" ]]; then
  log "installing gvm"
  bash < <(curl -fsSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
fi
# GVM's shell scripts are not compatible with strict Bash modes.
set +eu
# shellcheck disable=SC1090
source "$HOME/.gvm/scripts/gvm"
command -v gvm >/dev/null 2>&1 || { echo "gvm failed to load" >&2; exit 1; }
if ! gvm list | grep -q 'go1.26.8'; then
  log "installing Go 1.26.8"
  gvm install go1.26.8 -B || { echo "Go installation failed" >&2; exit 1; }
fi
gvm use go1.26.8 --default || { echo "could not select Go 1.26.8" >&2; exit 1; }
set -eu

if ! command -v rustup >/dev/null 2>&1; then
  log "installing rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
    sh -s -- -y --default-toolchain stable
fi
# shellcheck disable=SC1090
source "$HOME/.cargo/env"
rustup default stable
rustup component add rust-analyzer

if [[ "$(uname -s)" == Linux ]]; then
  if ! command -v bob >/dev/null 2>&1; then
    log "installing bob"
    curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh |
      bash
  fi
  bob install stable
  bob use stable
  export PATH="${XDG_DATA_HOME:-$HOME/.local/share}/bob/nvim-bin:$PATH"
fi

export PATH="$HOME/go/bin:$HOME/.cargo/bin:$PATH"
if ! command -v lf >/dev/null 2>&1; then
  log "installing lf"
  go install github.com/gokcehan/lf@latest
fi
if ! command -v jj >/dev/null 2>&1 || ! command -v tree-sitter >/dev/null 2>&1; then
  if ! command -v cargo-binstall >/dev/null 2>&1; then
    log "installing cargo-binstall"
    curl --proto '=https' --tlsv1.2 -sSfL \
      https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh |
      bash
  fi
fi
if ! command -v jj >/dev/null 2>&1; then
  log "installing jj"
  cargo binstall --no-confirm --locked jj-cli
fi
if ! command -v tree-sitter >/dev/null 2>&1; then
  log "installing tree-sitter CLI for Neovim parsers"
  cargo binstall --no-confirm --locked tree-sitter-cli
fi

log "done"
