{
  description = "Nixos";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: let
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
        ./configuration.nix
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
