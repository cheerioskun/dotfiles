#!/usr/bin/env bash
#
# Common installation functions shared between macOS and Linux
#

# Install TPM (Tmux Plugin Manager)
install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [[ -d "$tpm_dir" ]]; then
        log_info "TPM already installed"
        return 0
    fi

    log_info "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
    log_success "TPM installed (run prefix + I inside tmux to install plugins)"
}

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

path_prepend_if_dir() {
    local dir="$1"

    if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
        export PATH="$dir:$PATH"
    fi
}

# Run a command directly as root, or via sudo for normal users.
run_privileged() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    elif command_exists sudo; then
        sudo "$@"
    else
        log_error "sudo is required to run: $*"
        return 1
    fi
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
            run_privileged apt-get update
            run_privileged apt-get install -y zsh
        fi
        log_success "zsh installed"
    fi
}

# Set zsh as default shell
set_default_shell() {
    local zsh_path
    local user_shell

    zsh_path=$(command -v zsh)
    user_shell=""

    if [[ "$OS" == "macos" ]]; then
        user_shell=$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}' || true)
    elif command_exists getent; then
        user_shell=$(getent passwd "$(id -un)" | cut -d: -f7)
    fi

    if [[ "$user_shell" == "$zsh_path" ]]; then
        log_info "zsh is already the default shell"
        return 0
    fi

    log_info "Setting zsh as default shell..."

    # Add zsh to /etc/shells if not present
    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
        printf '%s\n' "$zsh_path" | run_privileged tee -a /etc/shells > /dev/null
    fi

    run_privileged chsh -s "$zsh_path" "$(id -un)" || log_warn "Could not change default shell. You may need to do this manually."
}

# Ensure ~/.local/bin is in PATH
ensure_local_bin() {
    local local_bin="$HOME/.local/bin"
    mkdir -p "$local_bin"

    if [[ ":$PATH:" != *":$local_bin:"* ]]; then
        log_info "Added $local_bin to PATH"
    fi
    path_prepend_if_dir "$local_bin"
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
    local binary_basename
    local install_dir="$HOME/.local/bin"
    local tmp_dir
    local resolved_binary
    local matches=()
    local match
    
    if command_exists "$cmd"; then
        log_info "$cmd is already installed"
        return 0
    fi
    
    log_info "Installing $cmd..."
    
    mkdir -p "$install_dir"
    
    tmp_dir="$(mktemp -d)"

    if ! (
        cd "$tmp_dir" &&
        curl -fsSL "$url" -o archive.tar.gz &&
        tar -xzf archive.tar.gz
    ); then
        rm -rf "$tmp_dir"
        log_error "Failed to download or extract $cmd from $url"
        return 1
    fi

    resolved_binary="$tmp_dir/$binary"
    if [[ ! -f "$resolved_binary" ]]; then
        binary_basename="$(basename "$binary")"
        while IFS= read -r match; do
            matches+=("$match")
        done < <(find "$tmp_dir" -type f -name "$binary_basename")

        if [[ ${#matches[@]} -eq 1 ]]; then
            resolved_binary="${matches[0]}"
        else
            rm -rf "$tmp_dir"
            if [[ ${#matches[@]} -eq 0 ]]; then
                log_error "Could not find $binary_basename in the extracted archive for $cmd"
            else
                log_error "Found multiple matches for $binary_basename in the extracted archive for $cmd"
            fi
            return 1
        fi
    fi

    mv "$resolved_binary" "$install_dir/$cmd"
    chmod +x "$install_dir/$cmd"
    rm -rf "$tmp_dir"
    
    log_success "$cmd installed to $install_dir"
}

# Install weave semantic merge driver (cross-platform)
# https://github.com/Ataraxy-Labs/weave
install_weave() {
    if command_exists weave-cli; then
        log_info "weave is already installed"
        return 0
    fi

    local target
    case "$(uname -s)-$(uname -m)" in
        Darwin-arm64)  target="aarch64-apple-darwin" ;;
        Darwin-x86_64) target="x86_64-apple-darwin" ;;
        Linux-x86_64)  target="x86_64-unknown-linux-gnu" ;;
        Linux-aarch64) target="aarch64-unknown-linux-gnu" ;;
        *) log_error "Unsupported platform for weave"; return 1 ;;
    esac

    install_github_release weave-cli \
        "https://github.com/Ataraxy-Labs/weave/releases/download/v0.2.0/weave-cli-${target}.tar.gz" \
        "weave"
}

# Install Rust via rustup (cross-platform)
# https://rustup.rs
install_rustup() {
    if command_exists cargo; then
        log_info "Rust/Cargo is already installed"
        return 0
    fi
    
    log_info "Installing Rust via rustup..."
    if ! (set -o pipefail; curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y); then
        log_error "Rust installation failed"
        return 1
    fi
    
    # Add cargo to PATH for current session
    if [[ -f "$HOME/.cargo/env" ]]; then
        source "$HOME/.cargo/env"
    else
        path_prepend_if_dir "$HOME/.cargo/bin"
    fi
    
    log_success "Rust installed"
}

# Install bun (cross-platform)
# https://bun.sh
install_bun() {
    if command_exists bun; then
        log_info "bun is already installed"
        return 0
    fi

    export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
    mkdir -p "$BUN_INSTALL/bin"
    path_prepend_if_dir "$BUN_INSTALL/bin"

    log_info "Installing bun..."
    if ! (set -o pipefail; curl -fsSL https://bun.com/install | bash); then
        log_error "bun installation failed"
        return 1
    fi

    path_prepend_if_dir "$BUN_INSTALL/bin"
    log_success "bun installed"
}

install_nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        log_info "nvm is already installed"
    else
        log_info "Installing nvm..."
        if ! (set -o pipefail; curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash); then
            log_error "nvm installation failed"
            return 1
        fi
        log_success "nvm installed"
    fi

    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        # shellcheck disable=SC1091
        source "$NVM_DIR/nvm.sh"
    else
        log_error "nvm installed but $NVM_DIR/nvm.sh is missing"
        return 1
    fi

    if ! command_exists npm; then
        log_info "Installing latest LTS Node.js with nvm..."
        nvm install --lts
    fi
}

install_codex() {
    if command_exists codex; then
        log_info "Codex is already installed"
        return 0
    fi

    install_nvm

    log_info "Installing Codex via npm..."
    npm i -g @openai/codex
    log_success "Codex installed"
}

# Install opencode (cross-platform)
# https://opencode.ai
install_opencode() {
    if command_exists opencode; then
        log_info "opencode is already installed"
        return 0
    fi

    local opencode_bin="$HOME/.opencode/bin"
    mkdir -p "$opencode_bin"

    log_info "Installing opencode..."
    if ! (set -o pipefail; curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path); then
        log_error "opencode installation failed"
        return 1
    fi

    path_prepend_if_dir "$opencode_bin"
    log_success "opencode installed"
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
    if ! (set -o pipefail; curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash); then
        log_error "zoxide installation failed"
        return 1
    fi
    
    log_success "zoxide installed"
}
