#!/usr/bin/env bash
#
# Linux-specific installation (Debian/Ubuntu-based)
# For GitHub Codespaces and Coder workspaces
#

install_linux_required() {
    log_info "Running Linux required installation..."

    ensure_local_bin
    install_apt_packages
    ensure_zsh
    set_default_shell
}

install_linux_optional() {
    log_info "Running Linux optional installation..."

    run_optional_step "GitHub release binaries" install_github_packages
    run_optional_step "rustup" install_rustup
}

install_apt_packages() {
    log_info "Installing packages via apt..."

    log_info "Updating package lists..."
    run_privileged apt-get update
    
    local packages=(
        ca-certificates
        curl
        git
        zsh
        ripgrep
        bat
        fd-find
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
        run_privileged apt-get install -y "${packages_to_install[@]}"
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

    local installers=(
        "fzf:install_fzf"
        "lf:install_lf"
        "jj:install_jj_linux"
        "bun:install_bun"
        "opencode:install_opencode"
        "delta:install_delta"
        "weave-cli:install_weave"
    )
    local labels=()
    local pids=()
    local failed=()
    local entry
    local label
    local fn
    local i

    for entry in "${installers[@]}"; do
        label="${entry%%:*}"
        fn="${entry##*:}"
        "$fn" &
        labels+=("$label")
        pids+=("$!")
    done

    for i in "${!pids[@]}"; do
        if ! wait "${pids[$i]}"; then
            failed+=("${labels[$i]}")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed installers: ${failed[*]}"
        return 1
    fi
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

# Install delta (better git diffs)
# https://github.com/dandavison/delta
install_delta() {
    local arch="$(get_arch)"
    local target
    case "$arch" in
        amd64) target="x86_64-unknown-linux-gnu" ;;
        arm64) target="aarch64-unknown-linux-gnu" ;;
        *)     log_error "Unsupported architecture: $arch"; return 1 ;;
    esac

    install_github_release delta \
        "https://github.com/dandavison/delta/releases/download/0.18.2/delta-0.18.2-${target}.tar.gz" \
        "delta-0.18.2-${target}/delta"
}

# Install fzf fuzzy finder
# https://github.com/junegunn/fzf
install_fzf() {
    local arch="$(get_arch)"
    local target
    case "$arch" in
        amd64) target="amd64" ;;
        arm64) target="arm64" ;;
        *)     log_error "Unsupported architecture: $arch"; return 1 ;;
    esac

    install_github_release fzf \
        "https://github.com/junegunn/fzf/releases/download/v0.67.0/fzf-0.67.0-linux_${target}.tar.gz"
}
