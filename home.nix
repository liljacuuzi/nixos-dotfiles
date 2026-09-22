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
    dunst = "dunst";
    btop = "btop";
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
        displaypowersave = "xrandr --output eDP-1 --mode 1920x1200 --rate 60 | feh --bg-scale ~/Walls/1920x1200p/tokyo-text.png";
        displaybalanced = "xrandr --output eDP-1 --mode 2560x1600 --rate 60 | feh --bg-scale ~/Walls/2560x1600p/tokyo-text.png";
        displayperformance = "xrandr --output eDP-1 --mode 2560x1600 --rate 165 | feh --bg-scale ~/Walls/2560x1600p/tokyo-text.png";
        gamma = "xrandr --output eDP-1 --brightness";
          
        # restore nvim shellAliases
        vi = "nvim";
        vim = "nvim";

        # printing support
        cups-start  = "sudo systemctl start cups.socket cups.service && echo 'CUPS active'";
        cups-stop   = "sudo systemctl stop cups.service cups.socket && echo 'CUPS stopped'";
        cups-status = "systemctl status cups.service";
        #battery conservation
        batenable = "sudo legion_cli --donotexpecthwmon batteryconservation-enable";
        batdisable = "sudo legion_cli --donotexpecthwmon batteryconservation-disable";
      };
      
    initExtra = ''
      export PS1='\[\e[38;5;40m\]\u\[\e[0m\] in \[\e[38;5;33m\]\w\[\e[0m\] \\$ '
    '';
  };
    
  home.packages = with pkgs; [
    bat
    rofi-power-menu
    localsend
    rofi
    btop
    # required for pcmanfm-qt
    pcmanfm-qt
    obsidian
  ];
  
services.udiskie = {
    enable = true;
    settings = {
        # workaround for
        # https://github.com/nix-community/home-manager/issues/632
        program_options = {
            # replace with your favorite file manager
            file_manager = "pcmanfm-qt";
        };
    };
};

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

  policies = {
    ExtensionSettings = {
      # keep your existing extensions
      "uBlock0@raymondhill.net" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        installation_mode = "force_installed";
      };
      "addon@darkreader.org" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/addon@darkreader.org/latest.xpi";
        installation_mode = "force_installed";
      };
      "tokyo-night-v3" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/tokyo-night-v3/latest.xpi";
        installation_mode = "force_installed";
      };
    };
  };
  };   
  
  programs.autorandr = {
    enable = true;
    hooks = {
      postswitch = {
        "wallpaper" = "${pkgs.feh}/bin/feh --bg-scale ~/Walls/2560x1600p/tokyo-text.png";
      };
    };
profiles = {
    mobile = {
      fingerprint = {
        "eDP-1" = "00ffffffffffff00148f15340000000019230104b521147803d045ae513cbc230b505400000001010101010101010101010101010101000000100000000000000000000000000000000000fd0c30a52e2f52010a202020202020000000fe0045444f2053480a202020202020000000fc004546323551424136332e450a2002f9702079020020001738ec1115340000000019190b4546323551424136332e4521001dd50c0508000a400600ee2a51bee3bb35020b024554ee5f4c6492092378260009040000000000400000220028b27d0c85ff099f0007001f003f06df00c3800700b27d0c05ff099f0007001f003f06570d3b8d07000000000000000000439070207900002b000c27003ca400002700303b00002e00060044ee5f5364810015741a0000030330a500a08f016b02a5000000008d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004d90";  # from `autorandr --fingerprint`
      };
      config = {
        "eDP-1" = {
          enable = true;
          primary = true;
          mode = "2560x1600";
          position = "0x0";
          rate = "165";  # or whatever your panel reports
        };
      };
    };
    docked = {
      fingerprint = {
        "eDP-1" = "00ffffffffffff00148f15340000000019230104b521147803d045ae513cbc230b505400000001010101010101010101010101010101000000100000000000000000000000000000000000fd0c30a52e2f52010a202020202020000000fe0045444f2053480a202020202020000000fc004546323551424136332e450a2002f9702079020020001738ec1115340000000019190b4546323551424136332e4521001dd50c0508000a400600ee2a51bee3bb35020b024554ee5f4c6492092378260009040000000000400000220028b27d0c85ff099f0007001f003f06df00c3800700b27d0c05ff099f0007001f003f06570d3b8d07000000000000000000439070207900002b000c27003ca400002700303b00002e00060044ee5f5364810015741a0000030330a500a08f016b02a5000000008d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004d90";
        "HDMI-1-0" = "00ffffffffffff001e6d555b01010101011a010380301b78ea3135a5554ea1260c5054a54b00714f81809500b300a9c0810081c09040023a801871382d40582c4500e00e1100001e000000fd00384b1e5512000a202020202020000000fc004c472046554c4c2048440a2020000000ff000a202020202020202020202020016102031bf14890040301121f1013230907078301000065030c001000023a801871382d40582c4500e00e1100001e2a4480a07038274030203500e00e1100001e011d007251d01e206e285500e00e1100001e8c0ad08a20e02d10103e9600e00e11000018000000000000000000000000000000000000000000000000000000004b";
      };
      config = {
        "eDP-1" = {
          enable = true;
          primary = true;
          mode = "2560x1600";
          position = "0x0";
        };
        "HDMI-1-0" = {
          enable = true;
          mode = "1920x1080";
          position = "2560x0";  # right of laptop
        };
      };
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
