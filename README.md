# Dotfiles

Personal shell and tool configuration, managed with chezmoi. Supports macOS and Debian/Ubuntu Linux without Nix.

```bash
git clone <repo-url> ~/repos/dotfiles
cd ~/repos/dotfiles
./bootstrap.sh
```

Bootstrap installs the system packages, applies `home/`, and sets up:

- zsh, tmux, fzf, ripgrep, fd, bat, lf, zoxide, jq, direnv, jj, and PostgreSQL's CLI
- stable Neovim through Bob, with a focused Lazy.nvim plugin set
- Node LTS through NVM
- Go 1.26.8 through GVM
- stable Rust through rustup
- Ghostty, Sublime Text, and JetBrains Mono Nerd Font on macOS

It is safe to run again. Machine-specific shell configuration belongs in `~/.zshrc.local`.

## Layout

```text
bootstrap.sh    shared setup and language managers
scripts/linux   apt packages and Linux shell setup
scripts/macos   Homebrew packages and macOS shell setup
home/           chezmoi source
```
