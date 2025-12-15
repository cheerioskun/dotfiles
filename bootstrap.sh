#!/usr/bin/env bash
#
# Dotfiles Bootstrap Script
# Works on macOS, GitHub Codespaces, and Coder workspaces
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script lives
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

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
        "zshrc:$HOME/.zshrc"
        "p10k.zsh:$HOME/.p10k.zsh"
    )
    
    for item in "${files[@]}"; do
        local src="${item%%:*}"
        local dest="${item##*:}"
        
        if [[ -e "$dest" ]] && [[ ! -L "$dest" ]]; then
            log_warn "Backing up existing $dest to ${dest}.backup"
            mv "$dest" "${dest}.backup"
        fi
        
        if [[ -L "$dest" ]]; then
            rm "$dest"
        fi
        
        ln -s "$DOTFILES_DIR/$src" "$dest"
        log_success "Linked $src -> $dest"
    done
}

# Main installation
main() {
    echo ""
    echo "=========================================="
    echo "       Dotfiles Bootstrap Script         "
    echo "=========================================="
    echo ""
    
    detect_os
    
    # Source common functions
    source "$DOTFILES_DIR/tools/common.sh"
    
    # Run OS-specific installation
    if [[ "$OS" == "macos" ]]; then
        source "$DOTFILES_DIR/tools/macos.sh"
        install_macos
    else
        source "$DOTFILES_DIR/tools/linux.sh"
        install_linux
    fi
    
    # Install antigen (common for both)
    install_antigen
    
    # Create symlinks
    create_symlinks
    
    echo ""
    log_success "Dotfiles installation complete!"
    echo ""
    log_info "Changing default shell to zsh..."
    sudo chsh $(whoami) -s $(which zsh)
    echo ""
}

# Run main function
main "$@"

