# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (`nixos-help`).

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
      XSECURELOCK_SAVER = "saver_xscreensaver";
      # B) Background image mode -- comment the line above, uncomment this:
      # XSECURELOCK_SAVER = "${oxwm-saver-image}/bin/saver_oxwm-image";

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

    # Toggle the panel between 60 Hz (battery) and 165 Hz (AC) at runtime.
    oxwm-battery-rate = pkgs.writeShellScriptBin "oxwm-battery-rate" ''
      set -eu

      # Use the rate passed as an argument ($1), defaulting to 60 if not specified
      RATE="''${1:-60}"

      # Identify the active internal eDP panel (eDP-1 or eDP-1-1)
      PANEL=$(${pkgs.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep ' connected' | ${pkgs.gnugrep}/bin/grep 'eDP' | ${pkgs.coreutils}/bin/cut -d' ' -f1)

      if [ -n "$PANEL" ]; then
        echo "Switching $PANEL to 2560x1600 @ ''${RATE}Hz"
        ${pkgs.xrandr}/bin/xrandr --output "$PANEL" --mode 2560x1600 --rate "$RATE"
      else
        echo "No eDP panel detected." >&2
        exit 1
      fi
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

  # ===== CachyOS kernel – BORE + ThinLTO (best pure AC performance) =====
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto;

  boot.kernelParams = [
    # Force PCIe Active State Power Management (ASPM)
    "pcie_aspm=force"
    # ...and prefer the most aggressive ASPM policy available
    "pcie_aspm.policy=powersupersave"
    # Enable deep sleep for NVMe drives
    "nvme_core.default_ps_max_latency_us=5000"
    # Intel i915 power saving features
    "i915.enable_fbc=1"
    "i915.enable_psr=1"

    "intel_pstate=active"

  ];

  # Intel HDA audio codec power management (powers down audio chip after 1s silence)
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=1 power_save_controller=Y
    options snd_ac97_codec power_save=1
    # Force runtime D3 (D3cold) on the dGPU; threshold 0 lets it suspend
    # even with a non-zero VRAM allocation.
    options nvidia NVreg_DynamicPowerManagement=0x02
    options nvidia NVreg_DynamicPowerManagementVideoMemoryThreshold=0
  '';

  networking.hostName = "nixos-laptop"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = true;
  # networking.wireless.enable = false; # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true; # Easiest to use with most DEs
  
  # attempt to reenable wifi
  hardware.enableRedistributableFirmware = true;

  # Set your time zone.

  # Allow unfree packages, necessary for steam
  nixpkgs.config.allowUnfree = true;

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };

  services.open-webui = {
    enable = true;
    port = 8080;
  };

  # Don't start these at boot: ollama-cuda's CUDA init pins the dGPU's PCIe
  # link in D0 even with no model loaded (upstream: ollama#8591). Start them
  # manually when you actually need them:
  #   sudo systemctl start ollama open-webui
  systemd.services.ollama.wantedBy = lib.mkForce [ ];
  systemd.services.open-webui.wantedBy = lib.mkForce [ ];
  systemd.services.syncthing.wantedBy = lib.mkForce [ ];

  # Enable power-profiles-daemon
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = lib.mkForce false;

  # Apply powertop's tunables (USB/PCI/SATA runtime PM) at boot.
  # CAVEAT: occasionally breaks touchpads, USB DACs and BT audio -- test it.
  powerManagement.powertop.enable = true;


  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    experimental-features = [ "nix-command" "flakes" ];
  };

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

    videoDrivers = [ "nvidia" ];
    dpi = 144; # 150% scaling (96 is default 100%
    # This avoids the xrandr issue with oxwm, keep this until oxwm fixes it
    displayManager.sessionCommands = ''
      # Allow local root to interact with X11 (required for systemd battery/AC hooks)
      ${pkgs.xorg.xhost}/bin/xhost +SI:localuser:root || true

      sleep 2
      ${pkgs.xrandr}/bin/xrandr --auto

      # Pick 60 Hz on battery, 165 Hz on AC (matches AC, ACAD, and Legion ADP1)
      if ${pkgs.gnugrep}/bin/grep -q '^0$' /sys/class/power_supply/{AC*,ADP*}/online 2>/dev/null; then
        RATE=60
      else
        RATE=165
      fi

      # Sync mode names (NVIDIA sync / docked profile)
      if ${pkgs.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep -q "HDMI-0 connected"; then
        ${pkgs.xrandr}/bin/xrandr \
          --output eDP-1-1 --mode 2560x1600 --rate "$RATE" --pos 0x0 --primary \
          --output HDMI-0  --mode 1920x1080 --pos 2560x0 --right-of eDP-1-1

      # Offload / on-the-go mode names (PRIME offload with external screen)
      elif ${pkgs.xrandr}/bin/xrandr | ${pkgs.gnugrep}/bin/grep -q "HDMI-1-0 connected"; then
        ${pkgs.xrandr}/bin/xrandr \
          --output eDP-1 --mode 2560x1600 --rate "$RATE" --pos 0x0 --primary \
          --output HDMI-1-0 --mode 1920x1080 --pos 2560x0 --right-of eDP-1

      else
        # Fallback – internal laptop panel only
        ${pkgs.xrandr}/bin/xrandr --output eDP-1 --mode 2560x1600 --rate "$RATE" 2>/dev/null \
          || ${pkgs.xrandr}/bin/xrandr --auto
      fi
    '';
    };


  # PAM so it can authenticate
  security.pam.services.xsecurelock = {};

  # Picom: never fade the lock screen windows (fixes the flash-on-unlock,
  # google/xsecurelock#97)
services.picom = {
  enable = true;
  backend = "xrender";          # keep this
  settings = {
    vsync = true;
    use-damage = true;         # ← try this first. use-damage=true is a common NVIDIA + rapid small windows killer
    # or keep use-damage = true and add the excludes below
    unredir-if-possible = true;  # unredirect fullscreen windows (video, games)

    # Completely ignore the notification windows for expensive operations
    fade-exclude = [
      "class_g = 'xsecurelock'"
      "class_g = 'Dunst'"
      "name = 'Dunst'"
    ];
    shadow-exclude = [
      "class_g = 'Dunst'"
      "name = 'Dunst'"
    ];
    opacity-rule = [
      "100:class_g = 'Dunst'"   # force full opacity, no blending cost
    ];

    # Optional but often helps on NVIDIA
    # glx-no-stencil = true;   # only relevant if you ever switch to glx
    # unredir-if-possible = true;
  };
};
  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS printing service
  services.printing.enable = true;
  # Prevent CUPS and its sockets/paths from starting automatically at boot
  systemd.services.cups.wantedBy = lib.mkForce [ ];
  systemd.sockets.cups.wantedBy = lib.mkForce [ ];
  systemd.paths.cups.wantedBy = lib.mkForce [ ];

  # Enable Sound / PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  # enables bluetooth 
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

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
    extraGroups = [ "wheel" "video" "audio" "networkmanager" "i2c" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ "smalldog" ]; # Replace with your actual username
      commands = [
        { command = "/run/current-system/sw/bin/legion_cli"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl start cups.service cups.socket"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl stop cups.service cups.socket"; options = [ "NOPASSWD" ]; }
        ];
      }
  ];

  # Virtual filesystem support (trash, USB mounting, network shares)
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    featherpad
    git
    brightnessctl
    alacritty
    picom
    oxwm
    feh
    mpv
    # terminal file manager
    yazi
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
    # legion tools
    lenovo-legion
    openrgb
    lm_sensors
    # manage app images (ankiengine)
    gearlever
  ];

  

  # Enable OpenRGB service for hardware control
  services.hardware.openrgb.enable = true;

  # Enable I2C access for OpenRGB
  hardware.i2c.enable = true;
  boot.kernelModules = [ "i2c-dev" "i2c-i801" "coretemp" "legion-laptop" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.lenovo-legion-module ];

  systemd.services.battery-mode = {
    description = "Drop GPU/network-heavy services on battery";
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${pkgs.systemd}/bin/systemctl --no-block stop \
        ollama.service \
        open-webui.service \
        syncthing.service \
        openrgb.service \
        tailscaled.service || true

      DISPLAY=:0 ${oxwm-battery-rate}/bin/oxwm-battery-rate 60
    '';
  };
  # Drop GPU/network-heavy services when unplugged.
  # Bring the always-wanted ones back when AC returns (ollama/open-webui stay
  # opt-in: start them by hand when you're actually developing).

  systemd.services.ac-mode = {
    description = "Restore services on AC";
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      ${pkgs.systemd}/bin/systemctl --no-block start \
        syncthing.service \
        tailscaled.service || true

      DISPLAY=:0 ${oxwm-battery-rate}/bin/oxwm-battery-rate 165
    '';
  };

  services.udev.extraRules = ''
  # ITE Tech Lenovo Legion RGB Controller
  SUBSYSTEM=="usb", ATTR{idVendor}=="048d", MODE="0666"
  SUBSYSTEM=="hidraw", ATTRS{idVendor}=="048d", MODE="0666"

  # Battery mode triggers (Wall unplugged -> quiet profile + power EPP + 60Hz)
  ACTION=="change", SUBSYSTEM=="power_supply", ATTR{online}=="0", \
    RUN+="${pkgs.systemd}/bin/systemctl --no-block start battery-mode.service", \
    RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver", \
    RUN+="${pkgs.lenovo-legion}/bin/legion_cli quiet"

  # AC plugged-in triggers (Wall plugged -> performance EPP + 165Hz)
  ACTION=="change", SUBSYSTEM=="power_supply", ATTR{online}=="1", \
    RUN+="${pkgs.systemd}/bin/systemctl --no-block start ac-mode.service", \
    RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance", \
    RUN+="${pkgs.lenovo-legion}/bin/legion_cli balanced"
'';

  environment.sessionVariables = {
    MOZ_X11_EGL = "1";                 # Critical for good X11 performance + VA-API
    MOZ_ENABLE_WAYLAND = "0";          # Force X11 path under OXWM
    LIBVA_DRIVER_NAME = "iHD";    # Explicit Mesa VA-API driver
    # Optional debug / force:
    # MOZ_DISABLE_RDD_SANDBOX = "1";   # Only if you hit sandbox issues with VA-API
    # MOZ_WEBRENDER = "1";
  };

  # Firefox 137 removed media.ffmpeg.vaapi.enabled; these are the current
  # equivalents for hardware decoding on X11. Check about:support afterwards:
  # HARDWARE_VIDEO_DECODING should be "Force enabled", and the Media section
  # should list H264_HW_DECODE / VP9_HW_DECODE as Supported.
    programs.firefox.preferences = {
    "media.hardware-video-decoding.force-enabled" = true;
    "gfx.x11-egl.force-enabled"                   = true;
    "widget.dmabuf.force-enabled"                 = true;
    "media.av1.enabled"                           = true;
  };

  # Enable hardware accelerated graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      mesa
      libva
      libva-utils
    ];
  };


 
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = false;

    powerManagement = {
      enable = true;
      finegrained = true; # Requires prime.offload.enable = true below
    };

    prime = {
      sync.enable = lib.mkForce false;

      offload = {
        enable = lib.mkForce true;
        enableOffloadCmd = lib.mkForce true;
      };

      intelBusId  = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Docked specialisation (sync mode for external monitors)
  specialisation = {
    docked.configuration = {
      system.nixos.tags = [ "docked" ];

      hardware.nvidia = {
        powerManagement.finegrained = lib.mkVMOverride false;

        prime = {
          offload.enable = lib.mkVMOverride false;
          offload.enableOffloadCmd = lib.mkVMOverride false;
          sync.enable = lib.mkVMOverride true;
        };
      };
    };
  };

  # Enable the Feral GameMode daemon properly
  programs.gamemode.enable = true;
  programs.steam = {
  enable = true;
  };
  # fsr 1.0 + forcing older games to launch at specified resolution
  programs.gamescope.enable = true;

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
    update.onActivation = false;          # update on every rebuild
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

  services.tailscale.enable = true;

  services.syncthing = {
    enable = true;
    user = "smalldog";
    configDir = "/home/smalldog/.config/syncthing";
    dataDir = "/home/smalldog";
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
  networking.firewall.allowedTCPPorts = [ 53317 22000 8384];
  networking.firewall.allowedUDPPorts = [ 53317 22000 21027];
  # syncthing ports


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
  # even if you've upgraded your system to a newer NixOS release.
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
