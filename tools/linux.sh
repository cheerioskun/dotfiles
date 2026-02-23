#!/usr/bin/env bash
#
# Linux-specific installation (Debian/Ubuntu-based)
# For GitHub Codespaces and Coder workspaces
#

install_linux() {
    log_info "Running Linux installation..."
    
    # Ensure ~/.local/bin exists and is in PATH
    ensure_local_bin
    
    # Add third-party apt repos before update so we only run apt-get update once
    setup_gh_apt_repo
    
    # Update package lists (single update covers all repos including gh)
    log_info "Updating package lists..."
    sudo apt-get update
    
    # Install packages via apt (includes gh)
    install_apt_packages
    
    # Ensure zsh is set up and set as default shell before installing tools
    ensure_zsh
    set_default_shell
    
    # Download binaries from GitHub releases (fzf, lf, jj in parallel)
    install_github_packages
    
    # Rust toolchain
    install_rustup
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
        gh
        unzip
    )
    
    # Check which packages need to be installed
    local packages_to_install=()
    for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            log_info "$pkg is already installed"
        else
            packages_to_install+=("$pkg")
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
    
    install_fzf &
    install_lf &
    install_jj_linux &
    install_bun &
    install_opencode &
    wait
}

# Add GitHub CLI apt repo (called before apt-get update so we only update once)
# https://github.com/cli/cli
setup_gh_apt_repo() {
    if command_exists gh; then
        return 0
    fi
    
    if [[ -f /usr/share/keyrings/githubcli-archive-keyring.gpg ]]; then
        return 0
    fi
    
    log_info "Adding GitHub CLI apt repository..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
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
