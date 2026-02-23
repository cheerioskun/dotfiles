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
    
    # psql client (keg-only, needs explicit linking)
    install_libpq
    
    # Ensure zsh is set up
    ensure_zsh
    
    # Rust toolchain
    install_rustup
    
    # Cross-platform curl installers
    install_bun
    install_opencode
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
        zoxide
        fd
        neovim
        jq
        jj
        iproute2mac
        less
        tmux
        gh
        direnv
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

install_libpq() {
    if command_exists psql; then
        log_info "psql is already available"
        return 0
    fi
    
    log_info "Installing libpq (PostgreSQL client tools)..."
    brew install libpq
    brew link --force libpq
    log_success "libpq installed and linked"
}

