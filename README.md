# Dotfiles

Personal shell and tool configuration, managed with chezmoi. Supports macOS and Debian/Ubuntu Linux without Nix.

```bash
git clone <repo-url> ~/repos/dotfiles
cd ~/repos/dotfiles
./bootstrap.sh
```

Bootstrap installs the system packages, applies `home/`, and sets up:

- zsh, Starship, tmux, fzf, ripgrep, fd, bat, lf, zoxide, jq, direnv, jj, and PostgreSQL's CLI
- stable Neovim (Homebrew on macOS, Bob on Linux), with NvChad
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

## Neovim

Uses [NvChad](https://nvchad.com/) v2.5 through Lazy.nvim, with the
[official starter](https://github.com/NvChad/starter) tracked in
`home/dot_config/nvim/` (starter revision `e3572e1f5e1c297212c3deeb17b7863139ce663e`).
No submodule or custom UI stack. Requires Neovim 0.11+, a Nerd Font, and the
Tree-sitter CLI (bootstrap installs it).

Open `nvim` to install plugins on first launch (including inside the container),
then run `:TSInstallAll` for syntax parsers. Use `:Lazy sync` for updates,
`:Mason` to install additional language tools, and `:NvCheatsheet` for mappings.
Space is the leader key. Defaults include:

- `<leader>ff`: find files; `<leader>fw`: search text
- `Ctrl-n`: file tree; `<leader>th`: theme picker
- `Alt-i`: floating terminal; `Ctrl-x`: leave terminal input mode
- `<leader>fm`: format; `<leader>ch`: keybinding cheatsheet

Configuration keeps NvChad's UI defaults, adding four-space indentation,
clangd, clang-format, and C/C++ syntax parsers.

### C/C++

The Linux setup includes clangd, clang-format, clang-tidy, CMake, Ninja, and GDB.
On macOS, install missing clangd/clang-format tools with `:Mason`.
`gd` jumps to definitions, `K` shows hover docs, `grr` finds references,
`<leader>ra` renames, and `gra` opens code actions.
`<leader>fm` formats with clang-format; project `.clang-format` files are respected.
Formatting is explicit, not automatic on save. Native `gcc` / `gc` comments code.

Generate compilation commands **inside the container**, so paths match:

```bash
cmake -S . -B build -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -sfn build/compile_commands.json compile_commands.json
cmake --build build
```

For non-CMake projects, supply `compile_commands.json` or `compile_flags.txt`.

## Layout

```text
bootstrap.sh    shared setup and language managers
scripts/linux   apt packages and Linux shell setup
scripts/macos   Homebrew packages and macOS shell setup
home/           chezmoi source
Dockerfile      devspace:latest workspace image
```
