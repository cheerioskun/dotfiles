#!/usr/bin/env bash
#
# Common installation functions shared between macOS and Linux
#

# Install antigen for zsh plugin management
install_antigen() {
    log_info "Installing antigen..."
    
    local antigen_path="$HOME/antigen.zsh"
    
    if [[ -f "$antigen_path" ]]; then
        log_info "Antigen already installed"
    else
        curl -L git.io/antigen > "$antigen_path"
        log_success "Antigen installed to $antigen_path"
    fi
    # Make completions directory (bug workaround)
    mkdir -p $HOME/.antigen/bundles/robbyrussell/oh-my-zsh/cache/completions
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

# =============================================================================
# Tool-specific installers for Linux
# =============================================================================

# Install lf file manager
# https://github.com/gokcehan/lf
install_lf() {
    if command_exists lf; then
        log_info "lf is already installed"
        return 0
    fi
    
    log_info "Installing lf..."
    
    local arch=$(get_arch)
    local install_dir="$HOME/.local/bin"
    mkdir -p "$install_dir"
    
    # lf uses /latest/download/ which auto-redirects to current version
    local url="https://github.com/gokcehan/lf/releases/latest/download/lf-linux-${arch}.tar.gz"
    
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    
    curl -sL "$url" -o lf.tar.gz
    tar -xzf lf.tar.gz
    mv lf "$install_dir/lf"
    chmod +x "$install_dir/lf"
    
    cd - > /dev/null
    rm -rf "$tmp_dir"
    
    log_success "lf installed to $install_dir"
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
