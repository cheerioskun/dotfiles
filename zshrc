# Dotfiles zshrc
# Portable configuration for macOS, GitHub Codespaces, and Coder workspaces

# =============================================================================
# Dotfiles Directory Detection
# =============================================================================

# Find the dotfiles directory (where this zshrc is symlinked from)
if [[ -L "$HOME/.zshrc" ]]; then
    DOTFILES_DIR="$(dirname "$(readlink "$HOME/.zshrc")")"
else
    # Fallback locations
    if [[ -d "$HOME/repos/dotfiles" ]]; then
        DOTFILES_DIR="$HOME/repos/dotfiles"
    elif [[ -d "$HOME/dotfiles" ]]; then
        DOTFILES_DIR="$HOME/dotfiles"
    elif [[ -d "$HOME/.dotfiles" ]]; then
        DOTFILES_DIR="$HOME/.dotfiles"
    fi
fi
export DOTFILES_DIR

# =============================================================================
# Powerlevel10k Instant Prompt
# =============================================================================
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =============================================================================
# PATH Configuration
# =============================================================================

# Add local bin directories
export PATH="$HOME/.local/bin:$PATH"

# Homebrew (macOS)
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# =============================================================================
# Antigen - Plugin Manager
# =============================================================================

# Load antigen
if [[ -f "$HOME/antigen.zsh" ]]; then
    source "$HOME/antigen.zsh"
    
    # Load antigen configuration
    if [[ -f "$DOTFILES_DIR/antigenrc" ]]; then
        source "$DOTFILES_DIR/antigenrc"
    fi
fi

# =============================================================================
# Source Custom Configs
# =============================================================================

# Source aliases
if [[ -f "$DOTFILES_DIR/aliases" ]]; then
    source "$DOTFILES_DIR/aliases"
fi

# Source functions
if [[ -f "$DOTFILES_DIR/functions" ]]; then
    source "$DOTFILES_DIR/functions"
fi

# =============================================================================
# Editor Configuration
# =============================================================================

if command -v nvim &> /dev/null; then
    export EDITOR='nvim'
    export VISUAL='nvim'
else
    export EDITOR='vim'
    export VISUAL='vim'
fi

# =============================================================================
# History Configuration
# =============================================================================

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY             # Share history between all sessions
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file
setopt HIST_VERIFY               # Do not execute immediately upon history expansion

# =============================================================================
# Powerlevel10k Configuration
# =============================================================================

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# =============================================================================
# Local Configuration (machine-specific, not tracked in git)
# =============================================================================

if [[ -f "$HOME/.zshrc.local" ]]; then
    source "$HOME/.zshrc.local"
fi

