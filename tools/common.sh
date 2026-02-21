#!/usr/bin/env bash
#
# Common installation functions shared between macOS and Linux
#

# Install zinit for zsh plugin management
install_zinit() {
    log_info "Installing zinit..."

    local zinit_home="$HOME/.local/share/zinit/zinit.git"

    if [[ -d "$zinit_home" ]]; then
        log_info "Zinit already installed"
        return 0
    fi

    mkdir -p "$(dirname "$zinit_home")"
    git clone https://github.com/zdharma-continuum/zinit.git "$zinit_home"
    log_success "Zinit installed to $zinit_home"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Install zsh if not present
ensure_zsh() {
    if command_exists zsh; then
        log_info "zsh is already installed"
    else
        log_info "Installing zsh..."
        if [[ "$OS" == "macos" ]]; then
            brew install zsh
        else
            sudo apt-get update && sudo apt-get install -y zsh
        fi
        log_success "zsh installed"
    fi
}

# Set zsh as default shell
set_default_shell() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        log_info "zsh is already the default shell"
    else
        log_info "Setting zsh as default shell..."
        local zsh_path
        zsh_path=$(which zsh)
        
        # Add zsh to /etc/shells if not present
        if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi
        
        chsh -s "$zsh_path" || log_warn "Could not change default shell. You may need to do this manually."
    fi
}

# Ensure ~/.local/bin is in PATH
ensure_local_bin() {
    local local_bin="$HOME/.local/bin"
    mkdir -p "$local_bin"
    
    if [[ ":$PATH:" != *":$local_bin:"* ]]; then
        export PATH="$local_bin:$PATH"
        log_info "Added $local_bin to PATH"
    fi
}

# Detect architecture
get_arch() {
    case "$(uname -m)" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        arm64)   echo "arm64" ;;
        *)       echo "unknown" ;;
    esac
}

# Download and install a binary from a GitHub release tarball.
# Usage: install_github_release <cmd> <url> [binary_name_in_archive]
#   cmd    - command name (used for existence check and destination filename)
#   url    - full URL to the .tar.gz asset
#   binary - name of the binary inside the archive (defaults to cmd)
install_github_release() {
    local cmd="$1"
    local url="$2"
    local binary="${3:-$cmd}"
    
    if command_exists "$cmd"; then
        log_info "$cmd is already installed"
        return 0
    fi
    
    log_info "Installing $cmd..."
    
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"
    
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    curl -sL "$url" -o archive.tar.gz
    tar -xzf archive.tar.gz
    mv "$binary" "$install_dir/$cmd"
    chmod +x "$install_dir/$cmd"
    
    cd - > /dev/null
    rm -rf "$tmp_dir"
    
    log_success "$cmd installed to $install_dir"
}

# Install Rust via rustup (cross-platform)
# https://rustup.rs
install_rustup() {
    if command_exists cargo; then
        log_info "Rust/Cargo is already installed"
        return 0
    fi
    
    log_info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # Add cargo to PATH for current session
    source "$HOME/.cargo/env"
    
    log_success "Rust installed"
}

# =============================================================================
# Tool-specific installers for Linux
# =============================================================================

# Install lf file manager
# https://github.com/gokcehan/lf
install_lf() {
    local arch=$(get_arch)
    install_github_release lf \
        "https://github.com/gokcehan/lf/releases/latest/download/lf-linux-${arch}.tar.gz"
}

# Install zoxide (smarter cd)
# https://github.com/ajeetdsouza/zoxide
install_zoxide() {
    if command_exists zoxide; then
        log_info "zoxide is already installed"
        return 0
    fi
    
    log_info "Installing zoxide..."
    
    # zoxide provides an install script that handles everything
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    
    log_success "zoxide installed"
}
