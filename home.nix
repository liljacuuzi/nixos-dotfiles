{ config, pkgs, ... }: 
let
  dotfiles = "${config.home.homeDirectory}/nixos-dotfiles/config";
  create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    awesome = "awesome";
    rofi = "rofi";
    pcmanfm-qt = "pcmanfm-qt";
    alacritty = "alacritty";
    nvim = "nvim";
    picom = "picom";
    oxwm = "oxwm";
    st = "st";
  };
in
    {
      imports = [
        ./scripts/notify.nix
        ./modules/neovim.nix
        ./modules/suckless.nix
      ];
      home.username = "smalldog";
      home.homeDirectory = "/home/smalldog";
      home.stateVersion = "26.05";
    
      programs.bash = {
        enable = true;
        shellAliases = {
          btw = "echo i use nixos btw";
          nrs = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-laptop";
          nrsu = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-laptop --upgrade";
          sncgd = "sudo nix-collect-garbage -d";
          ncg = "nix-collect-garbage";
          

          # restore nvim shellAliases
          vi = "nvim";
          vim = "nvim";
        };
      
        initExtra = ''
          export PS1='\[\e[38;5;40m\]\u\[\e[0m\] in \[\e[38;5;33m\]\w\[\e[0m\] \\$ '
        '';
      };
    
      home.packages = with pkgs; [
        bat
        localsend
        rofi
        feh
        # required for pcmanfm-qt
        pcmanfm-qt
      ];
     
     # Set pcmanfm-qt as the default file manager for directories
     xdg.mimeApps = {
       enable = true;
       defaultApplications = {
         "inode/directory" = [ "pcmanfm-qt.desktop" ];
       };
     };
     
     
     
     # symlink ~/.config to ~/nixos-dotfiles/config/ 
     xdg.configFile = builtins.mapAttrs (name: subpath: {
     source = create_symlink "${dotfiles}/${subpath}";
     }) configs;
     
   
   programs.firefox = {
  enable = true;
  profiles.myprofile = {
    settings = {
      # GPU & Hardware Acceleration
      "gfx.webrender.all" = true;
      "media.ffmpeg.vaapi.enabled" = true;
      "dom.webgpu.enabled" = true;

      # Performance Tweaks
      "network.dns.disablePrefetch" = false;
      "gfx.webrender.vsync.disabled" = true;
      
      # Video decoding optimizations
      "media.hardware-video-decoding.enabled" = true;
    };
  };
};
   
   
     # automatic git signing
     services.ssh-agent.enable = true;

     programs.ssh = {
       enable = true;
       # Fixes the 'enableDefaultConfig' warning
       enableDefaultConfig = false;

       # Fixes the 'matchBlocks' -> 'settings' deprecation warning
       settings = {
         "github.com" = {
           hostname = "github.com";
           user = "git";
           identityFile = "~/.ssh/id_ed25519"; 
         };
       };
     };

    programs.git = {
      enable = true;
      # Fixes 'userName', 'userEmail', and 'extraConfig' deprecation warnings
      settings = {
        user = {
          name = "liljacuuzi";
          email = "gurjotb81@gmail.com";
          signingkey = "~/.ssh/id_ed25519.pub";
        };
      gpg.format = "ssh";
      commit.gpgsign = true;
      };
    };
  }
