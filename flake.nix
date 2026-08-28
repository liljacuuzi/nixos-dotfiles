{
  description = "Nixos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Flatpak management
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    # Optional: pin a specific version instead
    # nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";

    # XLibre display server overlay
    xlibre-overlay.url = "git+https://codeberg.org/takagemacoed/xlibre-overlay?ref=dev-26.11";
    # xlibre-overlay.inputs.nixpkgs.follows = "nixpkgs";

  };

  outputs = { self, nixpkgs, home-manager, nix-flatpak, xlibre-overlay, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in
  {
    devShells.${system}.suckless = pkgs.mkShell {
      packages = with pkgs; [
        pkg-config
        libX11
        libXft
        libXinerama
        fontconfig
        freetype
        harfbuzz
        gcc
        gnumake
      ];
    };
nixosConfigurations.nixos-laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [

        # overlay 'xorg-server' to 'xlibre-xserver'
        xlibre-overlay.nixosModules.overlay-xlibre-xserver
        # Use the NixOS module from the flake
        xlibre-overlay.nixosModules.overlay-all-xlibre-drivers

        # NOTE: Use 'overlay-all-xlibre-drivers' instead if you also want 
        # XLibre-patched xf86-video-amdgpu / libinput drivers:
        # xlibre-overlay.nixosModules.overlay-all-xlibre-drivers

        ./configuration.nix

        # Enable declarative Flatpak support
        nix-flatpak.nixosModules.nix-flatpak

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.smalldog = import ./home.nix;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };

};
}
