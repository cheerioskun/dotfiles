{
  description = "hx's macOS and Ubuntu environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The module makes nix-darwin and Home Manager defer Nix itself to the
    # Determinate installation. It does not install Determinate Nix.
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    inputs@{
      determinate,
      home-manager,
      nix-darwin,
      nix-homebrew,
      nixpkgs,
      self,
      ...
    }:
    let
      username = "hx";
      linuxSystem = "x86_64-linux";
      supportedSystems = [
        linuxSystem
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      mkUbuntuHome =
        system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          extraSpecialArgs = {
            inherit inputs username;
            homeDirectory = "/home/${username}";
            isDarwin = false;
          };
          modules = [
            determinate.homeManagerModules.default
            ./modules/home
            ./hosts/ubuntu
          ];
        };
    in
    {
      darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit inputs username;
          homeDirectory = "/Users/${username}";
          isDarwin = true;
        };
        modules = [
          determinate.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          ./hosts/macbook
        ];
      };

      homeConfigurations = {
        "hx@ubuntu" = mkUbuntuHome linuxSystem;
      };

      # Keep the CLI on the same Home Manager revision as the configuration.
      # Ubuntu bootstrap can use:
      # nix run .#home-manager -- switch --flake .#hx@ubuntu
      packages = {
        x86_64-linux.home-manager =
          home-manager.packages.${linuxSystem}.home-manager;
        aarch64-darwin.darwin-rebuild =
          nix-darwin.packages.aarch64-darwin.darwin-rebuild;
      };

      checks = {
        x86_64-linux.home = self.homeConfigurations."hx@ubuntu".activationPackage;
        aarch64-darwin.system = self.darwinConfigurations.macbook.system;
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
