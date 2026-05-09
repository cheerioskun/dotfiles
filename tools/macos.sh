#!/usr/bin/env bash
#
# macOS-specific installation
#

install_macos_required() {
    log_info "Running macOS required installation..."

    install_homebrew
    ensure_local_bin
    install_iterm_preferences
    install_brew_packages
    install_libpq
    ensure_zsh
    set_default_shell
}

install_macos_optional() {
    log_info "Running macOS optional installation..."

    run_optional_step "rustup" install_rustup
    run_optional_step "bun" install_bun
    run_optional_step "nvm" install_nvm
    run_optional_step "codex" install_codex
    run_optional_step "opencode" install_opencode
    run_optional_step "weave" install_weave
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
        git-delta
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

install_iterm_preferences() {
    local src="$DOTFILES_DIR/config/iterm/com.googlecode.iterm2.plist"
    local dest="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    local backup

    if [[ ! -f "$src" ]]; then
        log_warn "iTerm2 preferences file is missing: $src"
        return 0
    fi

    log_info "Importing iTerm2 preferences..."

    if [[ -L "$dest" ]]; then
        log_warn "Removing iTerm2 preference symlink; macOS preferences do not reliably load it"
        rm "$dest"
    elif [[ -e "$dest" ]]; then
        backup="${dest}.backup.$(date +%Y%m%d-%H%M%S)"
        log_warn "Backing up existing iTerm2 preferences to $backup"
        mv "$dest" "$backup"
    fi

    defaults import com.googlecode.iterm2 "$src"
    killall cfprefsd >/dev/null 2>&1 || true
    log_success "Imported iTerm2 preferences. Fully quit and reopen iTerm2 to load them."
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
