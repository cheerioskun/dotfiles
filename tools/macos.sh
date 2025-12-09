#!/usr/bin/env bash
#
# macOS-specific installation
#

install_macos() {
    log_info "Running macOS installation..."
    
    # Install Homebrew if not present
    install_homebrew
    
    # Install packages via Homebrew
    install_brew_packages
    
    # Ensure zsh is set up
    ensure_zsh
}

install_homebrew() {
    if command_exists brew; then
        log_info "Homebrew is already installed"
    else
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        log_success "Homebrew installed"
    fi
}

install_brew_packages() {
    log_info "Installing packages via Homebrew..."
    
    local packages=(
        fzf
        ripgrep
        bat
        lf
        gum
        zoxide
        fd
        neovim
        jq
    )
    
    for pkg in "${packages[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            log_info "$pkg is already installed"
        else
            log_info "Installing $pkg..."
            brew install "$pkg"
            log_success "$pkg installed"
        fi
    done

}

