# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

let
    # ---- Your lock background ------------------------------------------------
    # Interpolated directly into the saver script at build time (xsecurelock
    # scrubs the environment before spawning children, so env vars can't be
    # relied upon inside savers).
    lockImage = "/home/smalldog/Walls/purple-sun-blurred.png";

    # ---- Lock screen saver selection -----------------------------------------
    # Pick EXACTLY ONE of the two XSECURELOCK_SAVER values below:
    #
    #   A) xscreensaver hacks -> saver_xscreensaver picks a random hack from
    #                            your ~/.xscreensaver "programs:" list
    #                            (run `xscreensaver-demo` once to create it!)
    #   B) image              -> our own saver module draws your wallpaper
    #                            into the lock window. This bypasses the
    #                            xscreensaver bridge entirely, because that
    #                            bridge ignores directories whenever
    #                            ~/.xscreensaver exists (it only reads the
    #                            programs list there), so a custom dir-based
    #                            "hack" can never be selected once
    #                            ~/.xscreensaver exists.
    #
    # NOTE: leaving BOTH uncommented is impossible -- Nix rejects duplicate
    # attributes -- so the config can never be ambiguous.
    xsecurelockSettings = {
      # Where the REAL xscreensaver hacks live (only used by mode A).
      XSECURELOCK_XSCREENSAVER_PATH = "${pkgs.xscreensaver}/libexec/xscreensaver";

      # A) Random xscreensaver hack mode:
      # XSECURELOCK_SAVER = "saver_xscreensaver";
      # B) Background image mode -- comment the line above, uncomment this:
      XSECURELOCK_SAVER = "${oxwm-saver-image}/bin/saver_oxwm-image";

      XSECURELOCK_BLANK_TIMEOUT = "1800";       # DPMS-off 30 min into lock
      XSECURELOCK_SAVER_STOP_ON_BLANK = "1";

      # Explicitly disabled to stop conflicts with picom
      XSECURELOCK_COMPOSITE_OBSCURER = "0";

      # TokyoNight (Night) palette styling
      XSECURELOCK_BACKGROUND_COLOR = "#1a1b26";
      XSECURELOCK_AUTH_BACKGROUND_COLOR = "#24283b";
      XSECURELOCK_AUTH_FOREGROUND_COLOR = "#c0caf5";
      XSECURELOCK_AUTH_WARNING_COLOR = "#f7768e";
      XSECURELOCK_FONT = "JetBrainsMono Nerd Font:size=14";
      XSECURELOCK_SHOW_DATETIME = "1";
      XSECURELOCK_DATETIME_FORMAT = "%H:%M • %A, %d %B";
      XSECURELOCK_PASSWORD_PROMPT = "time";
      XSECURELOCK_SHOW_HOSTNAME = "0";
      XSECURELOCK_SHOW_USERNAME = "1";
    };

    exportXsecurelockEnv =
      lib.concatStringsSep "\n"
      (lib.mapAttrsToList
        (name: value: ''export ${name}="${value}"'')
        xsecurelockSettings);

    lockEnv = ''
      # Rebuild a sane environment from /etc/passwd -- never trust the
      # inherited HOME (the /homeless-shelter bug).
      if [ -z "''${HOME:-}" ] || [ "$HOME" = "/homeless-shelter" ] || [ ! -d "$HOME" ]; then
        HOME="$(getent passwd "$(id -u)" | cut -d: -f6)"
        export HOME
      fi
      export USER="$(id -un)"
      export DISPLAY="''${DISPLAY:-:0}"
      # xscreensaver >= 6 hacks shell out to helpers living IN the hacks
      # directory (xscreensaver-getimage-*, xscreensaver-text, ...).
      export PATH="${pkgs.xscreensaver}/libexec/xscreensaver:${lib.makeBinPath [ pkgs.coreutils ]}:''${PATH:-}"
    '';

    oxwm-lock-warn = pkgs.writeShellScriptBin "oxwm-lock-warn" ''
      # Called by xidlehook when lock is imminent. Shows the countdown
      # notification and remembers its ID so it can be dismissed later.
      set -eu
      ID_FILE="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/oxwm-lock-notif-id"
      secs="''${1:-30}"
      id="$(notify-send -p -u critical -t "$((secs * 1000))" \
        -h string:x-dunst-stack-tag:oxwm-lock \
        'Screen Lock' "Locking in $secs seconds")"
      printf '%s' "$id" > "$ID_FILE"
    '';

    oxwm-lock-dismiss = pkgs.writeShellScriptBin "oxwm-lock-dismiss" ''
      # Dismisses the pending countdown notification (daemon-agnostic).
      ID_FILE="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/oxwm-lock-notif-id"
      [ -f "$ID_FILE" ] || exit 0
      id="$(cat "$ID_FILE")"
      rm -f "$ID_FILE"
      [ -n "$id" ] || exit 0
      if command -v gdbus >/dev/null 2>&1; then
        gdbus call --session \
          --dest org.freedesktop.Notifications \
          --object-path /org/freedesktop/Notifications \
          --method org.freedesktop.Notifications.CloseNotification "$id" >/dev/null 2>&1 || true
      else
        dunstctl close >/dev/null 2>&1 || true
      fi
    '';

    oxwm-lock = pkgs.writeShellScriptBin "oxwm-lock" ''
      # Main locker: used by xidlehook (idle) AND xss-lock (before suspend).

      ${lockEnv}

      ${exportXsecurelockEnv}

      /run/current-system/sw/bin/oxwm-lock-dismiss || true

      WAS_RUNNING=false
      if systemctl --user is-active --quiet picom.service; then
        WAS_RUNNING=true
        systemctl --user stop picom.service
      fi

      xsecurelock

      [ "$WAS_RUNNING" = true ] && systemctl --user start picom.service
    '';

    # A native xsecurelock saver module that fills the lock window with your
    # background image. xsecurelock accepts an ABSOLUTE path in
    # XSECURELOCK_SAVER (verified against its sources), so we don't need the
    # xscreensaver bridge (and its ~/.xscreensaver quirks) at all for this.
    oxwm-saver-image = pkgs.writeShellScriptBin "saver_oxwm-image" ''
      # xsecurelock saver protocol:
      #  - draw into/below $XSCREENSAVER_WINDOW
      #  - exit promptly on SIGTERM (when unlocking)

      echo "=== saver_oxwm-image started $(date -Is) ===" >&2

      img="${lockImage}"

      if [ ! -f "$img" ]; then
        echo "ERROR: image '$img' does not exist" >&2
        # Hold the window open (shows the background color) instead of dying;
        # a dead saver would make xsecurelock relaunch us in a tight loop.
        exec ${pkgs.coreutils}/bin/sleep infinity
      fi
      
      if [ -z "''${XSCREENSAVER_WINDOW:-}" ]; then
        echo "ERROR: XSCREENSAVER_WINDOW is not set" >&2
        exec ${pkgs.coreutils}/bin/sleep infinity
      fi

      echo "running mpv on window $XSCREENSAVER_WINDOW with $img" >&2
      
      # Use mpv to display the image indefinitely inside the xsecurelock window
      exec ${pkgs.mpv}/bin/mpv \
        --really-quiet \
        --no-config \
        --no-osc \
        --no-osd-bar \
        --no-input-default-bindings \
        --wid="$XSCREENSAVER_WINDOW" \
        --image-display-duration=inf \
        "$img"
    '';
    in
 
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "backup";
  home-manager.users.smalldog = import ./home.nix;


  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos-laptop"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;
  networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true; # Easiest to use with most DEs
  # Set your time zone.

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "America/Vancouver";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    displayManager.lightdm.enable = true; # Login manager
    windowManager.awesome.enable = true;
    windowManager.oxwm.enable = true;
  };

  # PAM so it can authenticate
  security.pam.services.xsecurelock = {};

  # Picom: never fade the lock screen windows (fixes the flash-on-unlock,
  # google/xsecurelock#97)
  services.picom = {
    enable = true;
    settings = {
      fade-exclude = [ "class_g = 'xsecurelock'" ];
    };
  };


  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput = {
    enable = true;
    touchpad.middleEmulation = true;
  };

  # fixing bug with not being able to write to files in home directory
  security.polkit.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.smalldog = {
    isNormalUser = true;
    initialPassword = "changeme";
    extraGroups = [ "wheel" "video" "audio" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  programs.firefox.enable = true;

  # Virtual filesystem support (trash, USB mounting, network shares)
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    xterm
    featherpad
    git
    brightnessctl
    alacritty
    picom
    oxwm
    feh
    mpv
    # copy/pasting text and screenshots
    xclip
    slop
    maim
    # required for notifications
    dunst
    libnotify
    # required for pcmanfm-qt
    lxmenu-data
    shared-mime-info
    # required for ligatures in st
    harfbuzz
    # Required for screen locking
    xsecurelock
    xidlehook
    xscreensaver
    glib
    oxwm-lock-warn
    oxwm-lock-dismiss
    oxwm-lock
  ];

  # Enable hardware accelerated graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  # Enable the Feral GameMode daemon properly
  programs.gamemode.enable = true;

  services.flatpak = {
    enable = true;  # you already have this

    # Flathub is added by default, but being explicit is fine
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    packages = [
      "org.vinegarhq.Sober"   # Sober from Flathub
      # add more apps here later if you want
    ];

    # Optional but recommended
    update.onActivation = true;          # update on every rebuild
    # or periodic:
    # update.auto = {
    #   enable = true;
    #   onCalendar = "weekly";
    # };
  };

  xdg.portal = {
    enable = true;
    # Most modern environments (GNOME, KDE Plasma, Hyprland) require an extra portal backend.
    # For general desktop compatibility, adding the gtk backend is highly recommended:
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };


  # Handle system suspend/hibernate locking via loginctl
  programs.xss-lock = {
    enable = true;
    lockerCommand = "/run/current-system/sw/bin/oxwm-lock";
  };
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];

  fonts.packages = with pkgs; [
    liberation_ttf
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?
}
