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

    # XLibre display server overlay
    xlibre-overlay.url = "git+https://codeberg.org/takagemacoed/xlibre-overlay?ref=dev-26.11";

    # CachyOS kernel (use /release for binary-cache hits)
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qylock = {
      url = "github:Darkkal44/qylock";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-flatpak, xlibre-overlay, nix-cachyos-kernel, antigravity-nix, silentSDDM, qylock, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { 
      inherit system;
      config.allowUnfree = true;
    };
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
        imlib2
        libXrender
        gcc
        gnumake
      ];
    };

    nixosConfigurations.nixos-laptop = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        # Overlays
        ({ lib, ... }: {
          nixpkgs.overlays = lib.mkBefore [
            nix-cachyos-kernel.overlays.pinned
            # Workaround: nixpkgs 26.11 added an X.Org-only patch inherited by xlibre-overlay
            (_final: prev:
              let
                stripDamagePatch = drv: drv.overrideAttrs (old: {
                  patches = builtins.filter
                    (p: !(lib.hasSuffix "revert-damage-unlink-abi-break.patch" (toString p)))
                    (old.patches or [ ]);
                });
              in
              (lib.optionalAttrs (prev ? xorg-server) {
                xorg-server = stripDamagePatch prev.xorg-server;
              })
              // (lib.optionalAttrs (prev ? xorg && prev.xorg ? xorgserver) {
                xorg =
                  if prev.xorg ? overrideScope then
                    prev.xorg.overrideScope (_: prevXorg: {
                      xorgserver = stripDamagePatch prevXorg.xorgserver;
                    })
                  else
                    prev.xorg // { xorgserver = stripDamagePatch prev.xorg.xorgserver; };
              })
            )
          ];
        })

        # XLibre modules
        xlibre-overlay.nixosModules.overlay-xlibre-xserver
        xlibre-overlay.nixosModules.overlay-all-xlibre-drivers

        ./configuration.nix

        # Flatpak support
        nix-flatpak.nixosModules.nix-flatpak

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.smalldog = import ./home.nix;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };
  };
}
