# Dotfiles

One personal environment for Apple Silicon macOS and x86_64 Ubuntu, expressed as a locked Nix flake.

The ownership boundaries are intentionally boring:

- Determinate installs and maintains Nix (native package on macOS, shell installer on Linux).
- nix-darwin owns the Mac system, fonts, and the minimal Homebrew boundary.
- Home Manager owns user packages and configuration on both platforms.
- mise owns Node, Go, and Rust versions.
- uv owns fast-moving Python tools such as Modal.
- Secrets, authentication, sessions, and `~/.zshrc.local` remain machine state.

There is no chezmoi, Zinit, TPM, NVM, Rustup, devenv, or compatibility layer.

## Fresh install

Clone the repository as the `hx` user, inspect the cleanup list printed by the script, then run:

```bash
# Apple Silicon macOS
./bootstrap.sh --fresh --host macbook

# x86_64 Ubuntu
./bootstrap.sh --fresh --host ubuntu
```

The bootstrap is deliberately destructive toward paths owned by older versions of this repository. It requires a typed confirmation; disposable test machines can use `--yes`.

It installs or repairs Determinate Nix, builds the selected configuration before deleting anything, removes only its explicit allowlist, activates the flake, and synchronizes mise/uv/npm-managed tools. It preserves Modal and Pi authentication, Pi sessions, SSH and Git state, `.zshrc.local`, and unrelated home files.

Every run saves its complete output to `~/Library/Logs/dotfiles/` on macOS or `${XDG_STATE_HOME:-~/.local/state}/dotfiles/` on Linux. The log path is printed at startup and on exit.

## Updating

Update pinned inputs deliberately:

```bash
nix flake update
```

Apply configuration changes without running the migration cleanup:

```bash
# macOS
sudo nix run .#darwin-rebuild -- switch --flake .#macbook

# Ubuntu
nix run .#home-manager -- switch --flake .#hx@ubuntu
```

Synchronize the non-Nix tool layer:

```bash
./scripts/sync-tools
```

The global mise defaults are Node LTS, latest Go, and stable Rust. Project files such as `.nvmrc`, `.node-version`, `go.mod`, and `rust-toolchain.toml` override those defaults.

## Layout

```text
flake.nix / flake.lock   pinned inputs and public outputs
hosts/                   explicit macbook and Ubuntu hosts
modules/darwin/          nix-darwin, fonts, and Homebrew
modules/home/            shared Home Manager modules
profiles/                package profiles
config/                  small static configurations
scripts/sync-tools       mise, uv, Pi, Modal, and skill sync
tests/                   isolated smoke tests and VM substrate
```

## Testing

Fast local checks:

```bash
bash tests/smoke.sh
nix build .#checks.x86_64-linux.home --no-link   # on Linux
nix build .#checks.aarch64-darwin.system --no-link  # on Apple Silicon
```

The Modal substrate probe boots a privileged Ubuntu 26.04 systemd guest inside a disposable Modal VM:

```bash
uv run tests/modal-systemd.py
uv run tests/modal-bootstrap.py             # brownfield install, then reinstall
uv run tests/modal-bootstrap.py --pristine  # cold pristine install, then reinstall
```

The evolving end-to-end contract lives in [TESTING.md](TESTING.md).
