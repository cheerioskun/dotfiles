# Dotfiles

Cross-platform dotfiles configuration for macOS, GitHub Codespaces, and Coder workspaces.

## What It Does

Automatically sets up your shell environment with:

- **zsh** with **zinit** plugin manager
- **Powerlevel10k** prompt (pre-configured, no wizard)
- Essential CLI tools: `fzf`, `ripgrep`, `bat`, `fd`, `lf`, `zoxide`, `jq`, `neovim`
- Custom aliases and functions for common tasks

## Quick Start

```bash
git clone <your-repo-url> ~/repos/dotfiles
cd ~/repos/dotfiles
./bootstrap.sh
```

The script will:
1. Detect your OS (macOS or Linux)
2. Install required tools via Homebrew (macOS) or apt/GitHub releases (Linux)
3. Install zinit plugin manager
4. Create symlinks for `~/.zshrc` and `~/.p10k.zsh`
5. Set zsh as default shell (Linux only)

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

## Requirements

- macOS: Homebrew (installed automatically if missing)
- Linux: Debian/Ubuntu-based system with `apt` and `sudo` access

