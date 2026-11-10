{ config, pkgs, lib, inputs, ... }: 
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
    yazi = "yazi";
    wal = "wal";
    "gtk-3.0" = "gtk-3.0";
    "gtk-4.0" = "gtk-4.0";
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
        displaypowersave = "PANEL=$(xrandr | awk '/eDP.*connected/ {print $1; exit}'); xrandr --output \"\${PANEL:-eDP-1}\" --mode 1920x1200 --rate 60 && (test -f ~/.fehbg && ~/.fehbg || feh --bg-scale ~/nixos-dotfiles/walls/1920x1200p/tokyo-text.png)";
        displaybalanced = "PANEL=$(xrandr | awk '/eDP.*connected/ {print $1; exit}'); xrandr --output \"\${PANEL:-eDP-1}\" --mode 2560x1600 --rate 60 && (test -f ~/.fehbg && ~/.fehbg || feh --bg-scale ~/nixos-dotfiles/walls/2560x1600p/tokyo-text.png)";
        displayperformance = "PANEL=$(xrandr | awk '/eDP.*connected/ {print $1; exit}'); xrandr --output \"\${PANEL:-eDP-1}\" --mode 2560x1600 --rate 165 && (test -f ~/.fehbg && ~/.fehbg || feh --bg-scale ~/nixos-dotfiles/walls/2560x1600p/tokyo-text.png)";
        gamma = "xrandr --output eDP-1 --brightness";
          
        # restore nvim shellAliases
        vi = "nvim";
        vim = "nvim";

        # printing support
        cups-start  = "sudo systemctl start cups.socket cups.service && echo 'CUPS active'";
        cups-stop   = "sudo systemctl stop cups.service cups.socket && echo 'CUPS stopped'";
        cups-status = "systemctl status cups.service";
        # battery conservation
        batenable = "sudo legion_cli --donotexpecthwmon batteryconservation-enable";
        batdisable = "sudo legion_cli --donotexpecthwmon batteryconservation-disable";

        # Pywal theme switch shortcut
        themeswitch = "$HOME/nixos-dotfiles/scripts/theme-switch.sh";

        # Colorized shell output
        ls = "ls --color=auto";
        ll = "ls -lh --color=auto";
        la = "ls -la --color=auto";
        l = "ls -CF --color=auto";
        grep = "grep --color=auto";
        diff = "diff --color=auto";
      };
      
    

    initExtra = ''
      # Apply pywal colors to every newly spawned terminal/shell
      [ -f "$HOME/.cache/wal/sequences" ] && cat "$HOME/.cache/wal/sequences"

      # Distinct file and directory colors using pywal terminal ANSI palette
      export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.zip=01;31:*.zst=01;31:*.7z=01;31:*.rar=01;31:*.gz=01;31:*.bz2=01;31:*.xz=01;31:*.png=01;35:*.jpg=01;35:*.jpeg=01;35:*.webp=01;35:*.gif=01;35:*.svg=01;35:*.bmp=01;35:*.ico=01;35:*.mp4=01;33:*.mkv=01;33:*.webm=01;33:*.avi=01;33:*.mov=01;33:*.mp3=00;36:*.flac=00;36:*.wav=00;36:*.ogg=00;36:*.m4a=00;36:*.opus=00;36:*.nix=01;36:*.lua=01;34:*.sh=01;32:*.bash=01;32:*.py=01;32:*.rs=01;31:*.go=01;36:*.c=01;33:*.h=01;33:*.cpp=01;33:*.js=01;33:*.ts=01;34:*.json=00;33:*.toml=00;33:*.yaml=00;33:*.yml=00;33:*.conf=00;36:*.rasi=00;36:*.pdf=01;31:*.md=01;37:*.txt=00;37:*~=00;90:*.bak=00;90:*.tmp=00;90:*.swp=00;90:*.lock=00;90:'
      export PS1='\[\e[38;5;40m\]\u\[\e[0m\] in \[\e[38;5;33m\]\w\[\e[0m\] \\$ '
    '';
  };
   
  programs.neovim = {
    defaultEditor = true;
  };

  home.packages = with pkgs; [
    bat
    rofi-power-menu
    localsend
    rofi
    btop
    # required for pcmanfm-qt
    (symlinkJoin {
      name = "pcmanfm-qt";
      paths = [
        (writeShellScriptBin "pcmanfm-qt" ''
          QSS="''${XDG_CACHE_HOME:-$HOME/.cache}/wal/pcmanfm-qt.qss"
          if [ -f "$QSS" ]; then
            exec ${pcmanfm-qt}/bin/pcmanfm-qt -stylesheet "$QSS" "$@"
          else
            exec ${pcmanfm-qt}/bin/pcmanfm-qt "$@"
          fi
        '')
        pcmanfm-qt
      ];
    })
    obsidian
    anki
    lutris
    _7zz
    # antigravity-cli
    inputs.antigravity-nix.packages.${pkgs.system}.google-antigravity-cli
    pywal16
    pywalfox-native
    xdotool
    xsettingsd
    glib
    gsettings-desktop-schemas
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "gtk3";
  };

  services.redshift = {
    # enable = true;

    # Displays temperature settings (in Kelvin)
    temperature = {
      day = 6500;
      night = 3500;
    };

    # Schedule Settings
    dawnTime = "6:00-7:00";
    duskTime = "19:00-21:00";
    

    # Coordinates based location
    provider = "manual";

    latitude = "49.94229149005969";
    longitude = "-119.39626552344195";
  };

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

  # Icon & GTK theme configuration
  gtk = {
    enable = true;
    theme = {
      name = "wal-a";
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.enable = false;
    gtk4.enable = false;
  };

  # DConf / GSettings interface configuration
  dconf.settings."org/gnome/desktop/interface" = {
    gtk-theme = "wal-a";
    icon-theme = "Papirus-Dark";
    color-scheme = "prefer-dark";
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  # Broadcast GTK & icon theme to running X11 apps via xsettings
  services.xsettingsd = {
    enable = true;
    settings = { };
  };

  systemd.user.services.xsettingsd.Service.ExecStart = lib.mkForce "${pkgs.xsettingsd}/bin/xsettingsd -c %h/.config/xsettingsd/xsettingsd.conf";

  # Dynamic Pywal GTK themes (wal-a & wal-b for live hot-reloading)
  xdg.dataFile."themes/wal-a/gtk-3.0/gtk.css".text = ''
    @import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained-dark.css");
    @import url("file://${config.home.homeDirectory}/.cache/wal/colors-gtk.css");
  '';
  xdg.dataFile."themes/wal-a/gtk-4.0/gtk.css".text = ''
    @import url("file://${config.home.homeDirectory}/.cache/wal/colors-gtk.css");
  '';
  xdg.dataFile."themes/wal-a/index.theme".text = ''
    [Desktop Entry]
    Type=X-GNOME-Metatheme
    Name=wal-a
    Comment=Pywal Dynamic Theme A
    Encoding=UTF-8

    [X-GNOME-Metatheme]
    GtkTheme=wal-a
    IconTheme=Papirus-Dark
  '';

  xdg.dataFile."themes/wal-b/gtk-3.0/gtk.css".text = ''
    @import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained-dark.css");
    @import url("file://${config.home.homeDirectory}/.cache/wal/colors-gtk.css");
  '';
  xdg.dataFile."themes/wal-b/gtk-4.0/gtk.css".text = ''
    @import url("file://${config.home.homeDirectory}/.cache/wal/colors-gtk.css");
  '';
  xdg.dataFile."themes/wal-b/index.theme".text = ''
    [Desktop Entry]
    Type=X-GNOME-Metatheme
    Name=wal-b
    Comment=Pywal Dynamic Theme B
    Encoding=UTF-8

    [X-GNOME-Metatheme]
    GtkTheme=wal-b
    IconTheme=Papirus-Dark
  '';

  # Legacy & Flatpak / user icon & theme compatibility
  home.file.".themes/wal-a".source = create_symlink "${config.home.homeDirectory}/.local/share/themes/wal-a";
  home.file.".themes/wal-b".source = create_symlink "${config.home.homeDirectory}/.local/share/themes/wal-b";
  home.file.".icons/Papirus-Dark".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";
  home.file.".icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";
  xdg.dataFile."icons/Papirus-Dark".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";
  xdg.dataFile."icons/Papirus".source = "${pkgs.papirus-icon-theme}/share/icons/Papirus";

  # Anki pywal theme addon integration
  home.file.".local/share/Anki2/addons21/pywal".source = create_symlink "${dotfiles}/anki/addons21/pywal";
        
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
      "pywalfox@frewacom.org" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/pywalfox/latest.xpi";
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
        "wallpaper" = "test -f ~/.fehbg && ~/.fehbg || ${pkgs.feh}/bin/feh --bg-scale ~/nixos-dotfiles/walls/2560x1600p/tokyo-text.png";
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
