# Hemant Nix

A slim opinionated NixOS flake for a VM-first Hyprland desktop.

Inspired by:

- `henrysipp/nix-setup` for small host constructors and profile thinking
- `henrysipp/omarchy-nix` for the Hyprland/Wayland desktop shape
- `mitchellh/nixos-config` for keeping machines explicit and boring

## What is in here

- Nix flakes enabled globally
- One primary user: `hemant`
- Hyprland + greetd/tuigreet
- Quickshell installed, with a tiny starter bar config
- Kitty, Firefox, wofi, mako, cliphist, hyprshot, hyprlock, swww/hyprpaper
- Shell/dev tooling mirrored from the existing dotfiles: zsh, tmux, neovim, fzf, ripgrep, fd, bat, lf, zoxide, jq, direnv, gh, jj, Go, Node, chezmoi
- A live ISO config for quickly booting a VM

Default live/VM password: `nixos`.

## Layout

```text
nix/
  flake.nix
  modules/
    base.nix              # NixOS basics, users, core CLI/dev tools
    desktop-hyprland.nix  # system Wayland/Hyprland services/packages
    home-manager.nix      # user shell + Hyprland + quickshell config
  hosts/
    vm/                   # installable VM profile
    iso/                  # live ISO profile
  scripts/build-iso       # convenience wrapper around nix build
```

## Build the ISO

From the repo root:

```bash
./nix/scripts/build-iso
```

Or with flakes directly:

```bash
nix run ./nix#iso
```

On Apple Silicon/Darwin, the helper targets `aarch64-linux` by default so the ISO is suitable for an ARM UTM VM. On Intel/non-ARM hosts it targets `x86_64-linux` by default. Override that any time with:

```bash
DOTFILES_ISO_SYSTEM=aarch64-linux ./nix/scripts/build-iso
DOTFILES_ISO_SYSTEM=x86_64-linux ./nix/scripts/build-iso
```

The ISO lands under:

```text
nix/result-iso/iso/hemant-nix-hyprland-<system>.iso
```

If you run `nix run ./nix#iso`, the result symlink is created in the current directory as `result-iso`.

> Building any Linux ISO from macOS requires a Linux builder. Darwin cannot locally build Linux NixOS derivations, even when the CPU architecture matches (`aarch64-darwin` is not `aarch64-linux`). The helper fails early on Darwin with a clear message instead of emitting many `platform mismatch` errors.
>
> For Apple Silicon UTM, boot an official `aarch64-linux` NixOS image first, clone this repo inside that VM, then run:
>
> ```bash
> ./nix/scripts/build-iso
> ```
>
> If you have a remote Linux builder, pass it explicitly:
>
> ```bash
> DOTFILES_NIX_BUILDERS='ssh-ng://nixos-builder aarch64-linux - 4 1 kvm,big-parallel' ./nix/scripts/build-iso
> ```
>
> If your builder is already configured in `nix.conf` but the helper cannot detect it, bypass the guard:
>
> ```bash
> DOTFILES_SKIP_PLATFORM_GUARD=1 ./nix/scripts/build-iso
> ```

## Try the installable VM config without making an ISO

On a Linux builder:

```bash
nix build ./nix#nixosConfigurations.vm.config.system.build.vm
./result/bin/run-hemant-vm-vm
```

## Install from the ISO later

Boot the ISO, partition your target disk, mount it under `/mnt`, then use this flake as the install source:

```bash
sudo nixos-install --flake /path/to/dotfiles/nix#vm
```

For real hardware, copy `nix/hosts/vm` to a new host folder, replace `fileSystems` with `nixos-generate-config` output, and add a new `nixosConfigurations.<host>` entry in `flake.nix`.

## First-login notes

This Nix config does not try to own every dotfile. After booting, you can still apply this repo's chezmoi-managed files:

```bash
git clone <repo-url> ~/repos/dotfiles
cd ~/repos/dotfiles
./bootstrap.sh
```

Keep machine-only secrets and overrides in `~/.zshrc.local`.
