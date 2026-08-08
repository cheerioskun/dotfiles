# Testing

This is the initial test contract for the Nix rewrite. Keep it short and amend it as the implementation teaches us what actually matters.

## Platforms

- macOS on Apple Silicon: GitHub Actions `macos-26`, plus a final smoke test on a real machine.
- Ubuntu 26.04: a systemd-enabled, privileged guest inside a Modal VM Sandbox.

Apple Containers are not a target: they test Linux containers, not a macOS `nix-darwin` installation.

## Test states

Run the installer against three disposable states:

1. A pristine OS.
2. A brownfield home produced by the old `main` bootstrap.
3. An already-configured machine, to prove a second fresh install works.

`tests/modal-bootstrap.py` combines each initial state with a reinstall in one disposable Ubuntu guest. Its default lane seeds brownfield state; `--pristine` keeps the cold-download lane separate so caching cannot hide installer assumptions.

The migration path is destructive by design. Tests should seed a sentinel file and authentication-shaped state to ensure the nuke removes only what it owns.

## Checks

- The bootstrap installs Determinate Nix and applies the correct flake host.
- Home Manager produces a clean, non-interactive Zsh startup.
- Core commands, tmux, Git/Jujutsu, Neovim, Ghostty, and Pi configuration are present.
- `mise` switches Node, Go, and Rust versions in small fixture projects.
- `uv` is present, Modal is uv-managed, and a read-only Modal authentication check succeeds when credentials are supplied.
- Unknown hosts and unsupported platforms fail clearly.
- Running the bootstrap twice succeeds.

## Speed

Modal supplies the disposable VM and real Linux kernel, but its own PID 1 is not systemd. The harness must boot the Ubuntu test guest with systemd rather than treating the Modal image itself as a normal workstation.

Keep one cold test that downloads everything. Use Modal filesystem snapshots for the normal Ubuntu loop: prepared VM, old-bootstrap state, Determinate Nix, and the current config keyed by `flake.lock`.

Start with the public Nix cache and CI caching. Add Cachix only if measurements show that snapshots and the standard cache are insufficient.

## Secrets

Never commit or bake Modal tokens, SSH keys, or application credentials into shared snapshots. CI receives short-lived credentials through its secret store; local auth remains machine state.
