# Dotfiles

Personal shell and tool configuration, managed with chezmoi. Supports macOS and Debian/Ubuntu Linux without Nix.

```bash
git clone <repo-url> ~/repos/dotfiles
cd ~/repos/dotfiles
./bootstrap.sh
```

Bootstrap installs the system packages, applies `home/`, and sets up:

- zsh, Starship, tmux, fzf, ripgrep, fd, bat, lf, zoxide, jq, direnv, jj, and PostgreSQL's CLI
- stable Neovim through Bob, with a focused Lazy.nvim plugin set
- Node LTS through NVM
- Go 1.26.8 through GVM
- stable Rust through rustup
- Ghostty, Sublime Text, and JetBrains Mono Nerd Font on macOS

It is safe to run again. Machine-specific shell configuration belongs in `~/.zshrc.local`.

## Devspace image

Build a ready-to-use workspace image:

```bash
docker build -t devspace:latest .
docker run --rm -it -v "$PWD:/workspace" devspace:latest
```

Use matching IDs on a Linux host if your account is not UID/GID 1000:

```bash
docker build \
  --build-arg UID="$(id -u)" \
  --build-arg GID="$(id -g)" \
  -t devspace:latest .
```

The image contains no host credentials. Mount SSH or other credentials explicitly when needed.

## C/C++ in Neovim

The Linux setup includes clangd, clang-format, clang-tidy, CMake, Ninja, and GDB.
Neovim requires 0.11+ (bootstrap installs stable). Completion uses native LSP;
`<C-y>` accepts a suggestion. `gd` jumps to definitions, `K` shows hover docs,
`grr` finds references, `<leader>cr` renames, and `<leader>ca` opens code actions.
`<leader>cf` formats with clang-format; project `.clang-format` files are respected.
Formatting is explicit, not automatic on save. Native `gcc` / `gc` comments code.

Generate compilation commands **inside the container**, so paths match:

```bash
cmake -S . -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -sfn build/compile_commands.json compile_commands.json
cmake --build build
```

For non-CMake projects, supply `compile_commands.json` or `compile_flags.txt`.
Run `:Lazy sync` after updating an existing installation; rebuild the image to
install the new system tools. `<leader>hb` toggles inline Git blame.

`Ctrl-\` toggles a floating terminal from both editor and terminal mode;
`<leader>tt` also opens it from normal mode. Run `make`, tests, or other shell
commands there. Hiding the terminal preserves the shell, history, scrollback,
and running jobs until Neovim exits. It starts in Neovim's launch directory;
use `cd` in the shell as needed. Double-Escape enters terminal normal mode to
scroll/copy; `i` resumes typing. `exit` ends the shell rather than hiding it.

## Layout

```text
bootstrap.sh    shared setup and language managers
scripts/linux   apt packages and Linux shell setup
scripts/macos   Homebrew packages and macOS shell setup
home/           chezmoi source
Dockerfile      devspace:latest workspace image
```
