#!/usr/bin/env bash
#
# Dotfiles Bootstrap Script
# Works on macOS, GitHub Codespaces, and Coder workspaces
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script lives
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

OPTIONAL_FAILURES=()

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

ensure_not_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        log_error "Do not run bootstrap as root. Run it as your normal user; sudo will be used only when needed."
        exit 1
    fi
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS="macos"
            ;;
        Linux)
            OS="linux"
            ;;
        *)
            log_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
    log_info "Detected OS: $OS"
}

# Create symlinks for config files
create_symlinks() {
    log_info "Creating symlinks..."
    
    local files=(
        "config/zshrc:$HOME/.zshrc"
        "config/p10k.zsh:$HOME/.p10k.zsh"
        "config/tmux.conf:$HOME/.tmux.conf"
        "config/psqlrc:$HOME/.psqlrc"
        "config/jjconfig.toml:$HOME/.jjconfig.toml"
        "config/iterm/com.googlecode.iterm2.plist:$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    )
    
    for item in "${files[@]}"; do
        local src="${item%%:*}"
        local dest="${item##*:}"
        local target="$DOTFILES_DIR/$src"
        local backup
        
        if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$target" ]]; then
            log_info "$dest already points to $target"
            continue
        fi

        if [[ -L "$dest" ]]; then
            rm "$dest"
        elif [[ -e "$dest" ]]; then
            backup="${dest}.backup.$(date +%Y%m%d-%H%M%S)"
            log_warn "Backing up existing $dest to $backup"
            mv "$dest" "$backup"
        fi

        ln -s "$target" "$dest"
        log_success "Linked $src -> $dest"
    done
}

run_optional_step() {
    local label="$1"
    shift

    if "$@"; then
        return 0
    fi

    OPTIONAL_FAILURES+=("$label")
    log_warn "Optional step failed: $label"
    return 0
}

verify_installation() {
    local failed=0
    local config_links=(
        "config/zshrc:$HOME/.zshrc"
        "config/p10k.zsh:$HOME/.p10k.zsh"
        "config/tmux.conf:$HOME/.tmux.conf"
        "config/psqlrc:$HOME/.psqlrc"
        "config/jjconfig.toml:$HOME/.jjconfig.toml"
        "config/iterm/com.googlecode.iterm2.plist:$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    )
    local path_checks=(
        "$HOME/.local/bin"
        "$HOME/.cargo/bin"
        "$HOME/.bun/bin"
        "$HOME/.opencode/bin"
    )
    local item
    local src
    local dest
    local target
    local dir

    log_info "Verifying installation..."

    for item in "${config_links[@]}"; do
        src="${item%%:*}"
        dest="${item##*:}"
        target="$DOTFILES_DIR/$src"

        if [[ ! -L "$dest" ]]; then
            log_error "Expected symlink missing: $dest"
            failed=1
        elif [[ "$(readlink "$dest")" != "$target" ]]; then
            log_error "Symlink points somewhere unexpected: $dest -> $(readlink "$dest")"
            failed=1
        fi
    done

    if ! command -v zsh >/dev/null 2>&1; then
        log_error "zsh is not installed or not on PATH"
        failed=1
    elif ! zsh -ic 'alias .. >/dev/null && alias gb >/dev/null && [[ -n "${DOTFILES_DIR:-}" ]]' >/dev/null 2>&1; then
        log_error "zsh could not load the managed aliases/config successfully"
        failed=1
    else
        log_success "zsh config loaded successfully"
    fi

    for dir in "${path_checks[@]}"; do
        if [[ -d "$dir" ]] && ! zsh -ic "[[ \":\$PATH:\" == *\":$dir:\"* ]]" >/dev/null 2>&1; then
            log_error "Managed PATH directory missing from zsh PATH: $dir"
            failed=1
        fi
    done

    return "$failed"
}

print_summary() {
    echo ""
    if [[ ${#OPTIONAL_FAILURES[@]} -gt 0 ]]; then
        log_warn "Installation completed with optional failures:"
        local failure
        for failure in "${OPTIONAL_FAILURES[@]}"; do
            echo "  - $failure"
        done
    else
        log_success "All optional installation steps succeeded"
    fi
    echo ""
}

maybe_exec_zsh() {
    if [[ "${DOTFILES_AUTO_EXEC_ZSH:-1}" != "1" ]]; then
        log_info "Skipping automatic shell handoff. Run 'exec zsh -l' when you want to load the new shell."
        return
    fi

    if [[ ! -t 0 || ! -t 1 ]]; then
        log_info "Bootstrap finished. Run 'exec zsh -l' in your terminal to load the new shell."
        return
    fi

    if ! command -v zsh >/dev/null 2>&1; then
        log_warn "zsh is not available to exec. Run 'exec zsh -l' after installing zsh."
        return
    fi

    log_info "Launching a login zsh so the new config is live in this terminal. Exit that shell to return."
    exec zsh -l
}

# Main installation
main() {
    echo ""
    echo "=========================================="
    echo "       Dotfiles Bootstrap Script         "
    echo "=========================================="
    echo ""

    ensure_not_root
    detect_os
    local installation_failed=0
    
    # Source common functions
    source "$DOTFILES_DIR/tools/common.sh"

    # Link configs first so the shell baseline exists even if optional installers fail later.
    create_symlinks
    
    # Run OS-specific installation
    if [[ "$OS" == "macos" ]]; then
        source "$DOTFILES_DIR/tools/macos.sh"
        install_macos_required
        install_macos_optional
    else
        source "$DOTFILES_DIR/tools/linux.sh"
        install_linux_required
        install_linux_optional
    fi
    
    # Optional shared tools
    run_optional_step "zinit" install_zinit
    run_optional_step "tmux plugin manager" install_tpm

    if ! verify_installation; then
        installation_failed=1
    fi
    print_summary

    if [[ "$installation_failed" -eq 0 ]]; then
        echo ""
        log_success "Dotfiles installation complete!"
        echo ""
        maybe_exec_zsh
    else
        log_error "Bootstrap finished with verification errors. Fix those before relying on this shell."
        return 1
    fi
}

# Run main function
main "$@"
