# Dotfiles

Cross-platform dotfiles configuration for macOS, GitHub Codespaces, and Coder workspaces.

## What It Does

Automatically sets up your shell environment with:

- **zsh** with **zinit** plugin manager
- **Powerlevel10k** prompt (pre-configured, no wizard)
- Essential CLI tools: `fzf`, `ripgrep`, `bat`, `fd`, `lf`, `zoxide`, `jq`, `neovim`
- Custom aliases and functions for common tasks
- `opencode`, `bun`, `nvm`, Codex, and `rustup` are installed into user-local locations and added to `PATH` by `zsh`
- iTerm2 preferences are imported from `config/iterm/com.googlecode.iterm2.plist`

## Quick Start

```bash
git clone <your-repo-url> ~/repos/dotfiles
cd ~/repos/dotfiles
./bootstrap.sh
```

The script will:
1. Detect your OS (macOS or Linux)
2. Install required tools via Homebrew (macOS) or apt/GitHub releases (Linux)
3. Create a managed source block in `~/.zshrc` and symlinks for `~/.p10k.zsh`, `~/.tmux.conf`, `~/.psqlrc`, and `~/.jjconfig.toml`
4. Import the iTerm2 preferences on macOS
5. Install zinit and TPM
6. Set `zsh` as the default shell on both macOS and Linux when possible
7. Reload into `zsh` at the end of bootstrap when run interactively

## Structure

```
dotfiles/
├── bootstrap.sh      # Main installation script
├── tools/            # OS-specific installers
├── zshrc             # Main zsh configuration
├── p10k.zsh          # Powerlevel10k theme config
├── aliases           # Shell aliases
└── functions         # Shell functions (rgz, lfcd, ff, killz, etc.)
```

## Key Features

- **rgz**: Interactive ripgrep + fzf search (CTRL-R for ripgrep mode, CTRL-F for fzf mode)
- **lfcd**: File manager that changes directory on exit
- **ff**: Find files with fzf
- **killz**: Kill processes via fzf
- **z**: Fuzzy directory jumping (via zoxide)

## Linux Validation

For a fresh Ubuntu 24.04 environment, validate the Linux path from `zsh` after bootstrap:

```bash
./bootstrap.sh
zsh -ic 'command -v fzf delta lf jj weave-cli bun opencode gh zoxide nvim'
zsh -ic 'fzf --version && delta --version && lf -version && jj --version && weave-cli --help >/dev/null'
```

First-run `zinit` plugin downloads are expected when `zsh` starts for the first time.

## Shell Reload

After bootstrap finishes in an interactive terminal, it will try to `exec zsh -l` so the new config is active immediately. If you prefer to stay in the current shell, set `DOTFILES_AUTO_EXEC_ZSH=0` before running the script.

## Requirements

- macOS: Homebrew (installed automatically if missing)
- Linux: Debian/Ubuntu-based system with `apt`; `sudo` is used automatically when not already running as `root`
