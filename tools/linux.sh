#!/usr/bin/env bash
#
# Linux-specific installation (Debian/Ubuntu-based)
# For GitHub Codespaces and Coder workspaces
#

install_linux() {
    log_info "Running Linux installation..."
    
    # Ensure ~/.local/bin exists and is in PATH
    ensure_local_bin
    
    # Update package lists
    log_info "Updating package lists..."
    sudo apt-get update
    
    # Install packages via apt
    install_apt_packages
    
    # Install packages not in apt from GitHub releases
    install_github_packages
    
    # Ensure zsh is set up
    ensure_zsh
    set_default_shell
}

install_apt_packages() {
    log_info "Installing packages via apt..."
    
    local packages=(
        zsh
        ripgrep
        bat
        fd-find
        curl
        git
        neovim
        jq
    )
    
    for pkg in "${packages[@]}"; do
        if dpkg -l "$pkg" &>/dev/null; then
            log_info "$pkg is already installed"
        else
            log_info "Installing $pkg..."
            sudo apt-get install -y "$pkg"
            log_success "$pkg installed"
        fi
    done
    
    # Create symlinks for renamed packages
    # bat is installed as batcat on Debian/Ubuntu
    if command_exists batcat && ! command_exists bat; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(which batcat)" "$HOME/.local/bin/bat"
        log_info "Created symlink: bat -> batcat"
    fi
    
    # fd is installed as fdfind on Debian/Ubuntu
    if command_exists fdfind && ! command_exists fd; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(which fdfind)" "$HOME/.local/bin/fd"
        log_info "Created symlink: fd -> fdfind"
    fi
}

install_github_packages() {
    log_info "Installing packages from GitHub releases..."
    
    # fzf fuzzy finder
    install_fzf
    
    # lf file manager
    install_lf
    
    # zoxide (smarter cd)
    install_zoxide
}

# Install fzf fuzzy finder
# https://github.com/junegunn/fzf
install_fzf() {
    if command_exists fzf; then
        log_info "fzf is already installed"
        return 0
    fi
    
    log_info "Installing fzf..."
    
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"
    
    local url="https://github.com/junegunn/fzf/releases/download/v0.67.0/fzf-0.67.0-linux_amd64.tar.gz"
    
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    curl -sL "$url" -o fzf.tar.gz
    tar -xzf fzf.tar.gz
    mv fzf "$install_dir/fzf"
    chmod +x "$install_dir/fzf"
    
    cd - > /dev/null
    rm -rf "$tmp_dir"
    
    log_success "fzf installed to $install_dir"
}
