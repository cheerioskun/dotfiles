# Dotfiles

This repo exists to make a new machine feel like mine quickly: a fast zsh, quiet muscle-memory aliases, tmux that behaves predictably, fuzzy search everywhere, sane CLI defaults, and pi available as the agent interface.

The north star is a declarative, cross-platform personal environment. Files are managed by chezmoi. `bootstrap.sh` is only the conventional entrypoint: it installs chezmoi if needed, applies this repo, and can install the current tool profiles.

## Principles

- **Config is precious; installers are disposable.** Dotfiles should describe the environment. Package installation is a helper, not the identity of the repo.
- **Cross-platform by default.** macOS and Debian/Ubuntu-like Linux should share the same shell feel.
- **Local escape hatches stay local.** Secrets, auth, session history, and machine-specific overrides are not tracked.
- **One obvious entrypoint.** A fresh machine should start with `./bootstrap.sh`.

## Bootstrap

```bash
git clone <repo-url> ~/repos/dotfiles
cd ~/repos/dotfiles
./bootstrap.sh
```

By default this applies the chezmoi-managed files and installs the `core,dev,ai` profiles. Override with:

```bash
DOTFILES_PROFILES=core ./bootstrap.sh
DOTFILES_PROFILES=core,dev,ai,macos-gui ./bootstrap.sh
DOTFILES_SKIP_PACKAGES=1 ./bootstrap.sh
```

Local machine overrides belong in `~/.zshrc.local`.

Tracked pi config includes settings and global extensions. Pi auth and sessions are intentionally not managed.
