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
    
    # Rust toolchain (needed before jj)
    install_rustup
    
    # jj (jujutsu) VCS
    install_jj_linux
    
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
        zoxide
        tmux
        postgresql-client
        direnv
    )
    
    # Check which packages need to be installed
    local packages_to_install=()
    for pkg in "${packages[@]}"; do
        if ! dpkg -l "$pkg" &>/dev/null; then
            packages_to_install+=("$pkg")
        else
            log_info "$pkg is already installed"
        fi
    done
    
    # Install all missing packages at once
    if [ ${#packages_to_install[@]} -gt 0 ]; then
        log_info "Installing packages: ${packages_to_install[*]}..."
        sudo apt-get install -y "${packages_to_install[@]}"
        log_success "All packages installed"
    fi
    
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
    
    # GitHub CLI
    install_gh_linux
}

# Install GitHub CLI
# https://github.com/cli/cli
install_gh_linux() {
    if command_exists gh; then
        log_info "gh is already installed"
        return 0
    fi
    
    log_info "Installing GitHub CLI..."
    
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y gh
    
    log_success "gh installed"
}

# Install jj (jujutsu) VCS from GitHub release
# https://github.com/jj-vcs/jj
install_jj_linux() {
    local arch=$(get_arch)
    local target
    case "$arch" in
        amd64) target="x86_64-unknown-linux-musl" ;;
        arm64) target="aarch64-unknown-linux-musl" ;;
        *)     log_error "Unsupported architecture: $arch"; return 1 ;;
    esac
    install_github_release jj \
        "https://github.com/jj-vcs/jj/releases/download/v0.38.0/jj-v0.38.0-${target}.tar.gz"
}

# Install fzf fuzzy finder
# https://github.com/junegunn/fzf
install_fzf() {
    install_github_release fzf \
        "https://github.com/junegunn/fzf/releases/download/v0.67.0/fzf-0.67.0-linux_amd64.tar.gz"
}
