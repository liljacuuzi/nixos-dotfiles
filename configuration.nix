# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

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
  # networking.networkmanager.enable = true; # Easiest to use and most distros use this by default
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
  # services.xserver.enable = true;
  services.xserver = {
    enable = true;

    displayManager.lightdm.enable = true; # Login manager
    windowManager.awesome.enable = true;
    windowManager.oxwm.enable = true;
  };

  # PAM so it can authenicate
  security.pam.services.xsecurelock = {};

  # Enable picom services
  services.picom = {
    enable = true;
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
      # Required for scree locking
      xsecurelock
      xidlehook
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

  environment.sessionVariables = {
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

 # Handle system suspend/hibernate locking via loginctl
  programs.xss-lock = {
    enable = true;
    lockerCommand = "${pkgs.xsecurelock}/bin/xsecurelock";
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

