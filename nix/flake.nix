{
  description = "Hemant's slim opinionated NixOS + Hyprland setup";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      lib = nixpkgs.lib;
      linuxSystem = "x86_64-linux";
      linuxAarch64System = "aarch64-linux";
      desktopUser = "hemant";
      allSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs allSystems;

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      defaultIsoTargetFor =
        system: if lib.hasPrefix "aarch64" system then linuxAarch64System else linuxSystem;

      isoConfigFor =
        targetSystem:
        if targetSystem == linuxAarch64System then
          "iso-aarch64"
        else if targetSystem == linuxSystem then
          "iso-x86_64"
        else
          throw "Unsupported ISO target system: ${targetSystem}";

      mkApp =
        system: name: text:
        let
          pkgs = pkgsFor system;
          package = pkgs.writeShellApplication {
            inherit name text;
            runtimeInputs = [
              pkgs.coreutils
              pkgs.findutils
              pkgs.gnugrep
              pkgs.nix
            ];
          };
        in
        {
          type = "app";
          program = "${package}/bin/${name}";
          meta.description = "Build the Hemant Nix Hyprland live ISO";
        };

      mkNixos =
        system: modules:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = commonModules ++ modules;
        };

      commonModules = [
        ./modules/base.nix
        ./modules/desktop-hyprland.nix
        home-manager.nixosModules.home-manager
        ./modules/home-manager.nix
        {
          nixpkgs.config.allowUnfree = true;
          dotfiles.userName = desktopUser;
        }
      ];
    in
    {
      formatter = forAllSystems (system: (pkgsFor system).nixfmt);

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nil
              nixd
              nixfmt
            ];
          };
        }
      );

      apps = forAllSystems (system: {
        iso = mkApp system "dotfiles-build-iso" ''
          set -euo pipefail
          out="''${DOTFILES_ISO_OUT:-result-iso}"
          flake="''${DOTFILES_NIX_FLAKE:-${self}}"
          target_system="''${DOTFILES_ISO_SYSTEM:-${defaultIsoTargetFor system}}"
          current_system="$(nix eval --impure --raw --expr 'builtins.currentSystem' 2>/dev/null || echo unknown)"

          case "$target_system" in
            ${linuxSystem}) config_name="${isoConfigFor linuxSystem}" ;;
            ${linuxAarch64System}) config_name="${isoConfigFor linuxAarch64System}" ;;
            *) echo "[nix] unsupported ISO target system: $target_system" >&2; exit 2 ;;
          esac

          nix_args=()
          if [[ -n "''${DOTFILES_NIX_BUILDERS:-}" ]]; then
            nix_args+=(--builders "''${DOTFILES_NIX_BUILDERS}" --builders-use-substitutes)
          fi

          has_linux_builder=false
          if [[ -n "''${DOTFILES_NIX_BUILDERS:-}" ]] || nix config show builders 2>/dev/null | grep -q -- "$target_system"; then
            has_linux_builder=true
          fi
          for arg in "$@"; do
            case "$arg" in
              --builders|--builders=*|--option)
                has_linux_builder=true
                ;;
            esac
          done

          if [[ "$current_system" != "$target_system" && "$has_linux_builder" != true && "''${DOTFILES_SKIP_PLATFORM_GUARD:-}" != 1 ]]; then
            cat >&2 <<EOF
          [nix] this ISO is a $target_system NixOS image, but this machine is $current_system.
          [nix] macOS cannot locally build Linux NixOS derivations, even when the CPU architecture matches.
          [nix]
          [nix] Fix: run this inside an existing $target_system VM/host, or provide a Linux remote builder, e.g.
          [nix]   DOTFILES_NIX_BUILDERS='ssh-ng://nixos-builder $target_system - 4 1 kvm,big-parallel' nix run ./nix#iso
          [nix]
          [nix] For Apple Silicon UTM, boot an official aarch64-linux NixOS image first, clone this repo, then build there.
          [nix]
          [nix] If your Linux builder is already configured in nix.conf but not detected, rerun with:
          [nix]   DOTFILES_SKIP_PLATFORM_GUARD=1 nix run ./nix#iso
          EOF
            exit 1
          fi

          echo "[nix] building Hyprland live ISO for $target_system from $flake#$config_name"
          echo "[nix] host: $current_system"
          echo "[nix] output symlink: $out"
          nix build "''${nix_args[@]}" "$flake#nixosConfigurations.$config_name.config.system.build.isoImage" -o "$out" "$@"

          iso_path=$(find -L "$out/iso" -maxdepth 1 -type f -name '*.iso' | head -n 1 || true)
          if [ -n "$iso_path" ]; then
            echo "[nix] iso: $iso_path"
          else
            echo "[nix] built, but could not locate an .iso under $out/iso" >&2
          fi
        '';
      });

      nixosConfigurations = {
        vm-x86_64 = mkNixos linuxSystem [ ./hosts/vm ];
        vm-aarch64 = mkNixos linuxAarch64System [ ./hosts/vm ];

        iso-x86_64 = mkNixos linuxSystem [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix"
          ./hosts/iso
        ];
        iso-aarch64 = mkNixos linuxAarch64System [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-base.nix"
          ./hosts/iso
        ];

        # Backwards-compatible aliases.
        vm = self.nixosConfigurations.vm-x86_64;
        iso = self.nixosConfigurations.iso-x86_64;
      };
    };
}
