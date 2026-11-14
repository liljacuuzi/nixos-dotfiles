# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, inputs, ... }:

let
    # Fallback wallpaper for SilentSDDM (matches themeswitch default)
    defaultSddmWallpaper = "/home/smalldog/nixos-dotfiles/walls/2560x1600p/tokyo-text.png";

    # Dynamic Matugen SilentSDDM theme (Material You)
    silentSDDMTheme = pkgs.stdenv.mkDerivation {
      pname = "silent";
      version = "unstable";
      src = inputs.silentSDDM;
      installPhase = ''
        mkdir -p $out/share/sddm/themes/silent
        cp -r * $out/share/sddm/themes/silent/

        # Point active config to /var/cache/matugen-sddm/silent.conf
        ln -sfn /var/cache/matugen-sddm/silent.conf $out/share/sddm/themes/silent/configs/matugen.conf
        sed -i 's|^ConfigFile=.*|ConfigFile=configs/matugen.conf|' $out/share/sddm/themes/silent/metadata.desktop

        # Point active background to /var/cache/matugen-sddm/wallpaper.png
        ln -sfn /var/cache/matugen-sddm/wallpaper.png $out/share/sddm/themes/silent/backgrounds/matugen.png
      '';
    };

    # ---- Your lock background ------------------------------------------------
    # Interpolated directly into the saver script at build time (xsecurelock
    # scrubs the environment before spawning children, so env vars can't be
    # relied upon inside savers).
    lockImage = "/home/smalldog/nixos-dotfiles/walls/purple-sun-blurred.png";

    # ---- Lock screen saver & hybrid frosted wallpaper configuration ----------
    # Flow when locked:
    #   1. Displays the pre-rendered dual_kawase frosted wallpaper
    #      (~/.cache/matugen/lock-wallpaper.png, with fallback to lockImage)
    #   2. After 60s of continuous inactivity while locked, transitions into
    #      a random xscreensaver hack from ~/.xscreensaver
    #   3. Upon any mouse movement or keypress, immediately stops the
    #      xscreensaver hack, restores the frosted dual_kawase wallpaper, and
    #      opens the Base16-themed auth_x11 password prompt.
    xsecurelockSettings = {
      # Where the REAL xscreensaver hacks live.
      XSECURELOCK_XSCREENSAVER_PATH = "${pkgs.xscreensaver}/libexec/xscreensaver";

      # Hybrid saver: frosted dual_kawase wallpaper <-> xscreensaver on idle
      XSECURELOCK_SAVER = "${oxwm-saver-hybrid}/bin/saver_oxwm-hybrid";
      XSECURELOCK_SAVER_RESET_ON_AUTH_CLOSE = "1";
      XSECURELOCK_SAVER_IDLE_TIMEOUT = "60";    # 60s on frosted wallpaper before xscreensaver starts
      XSECURELOCK_SAVER_DELAY_MS = "80";        # Let saver paint frosted image before mapping window

      XSECURELOCK_BLANK_TIMEOUT = "1800";       # DPMS-off 30 min into lock
      XSECURELOCK_SAVER_STOP_ON_BLANK = "1";

      # Explicitly disabled to stop conflicts with picom
      XSECURELOCK_COMPOSITE_OBSCURER = "0";
      XSECURELOCK_DISCARD_FIRST_KEYPRESS = "0";

      # Fallback TokyoNight (Night) palette styling (overridden dynamically by matugen Base16 in oxwm-lock)
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
      export PATH="${pkgs.xscreensaver}/libexec/xscreensaver:${lib.makeBinPath [ pkgs.coreutils pkgs.imagemagick ]}:''${PATH:-}"
    '';

    # Native X11 + Imlib2 helpers:
    #  1) oxwm-set-win-bg: paints the frosted wallpaper directly onto
    #     xsecurelock's $XSCREENSAVER_WINDOW (both as background_pixmap and via
    #     Expose/MapNotify events) using ~1.5 MB RAM and 0% CPU.
    #  2) oxwm-wait-input: monitors live X11 pointer coordinates (XQueryPointer)
    #     and keymap state (XQueryKeymap) every 80ms; returns 0 immediately on
    #     any mouse movement or keypress, or 1 if timeout_ms elapses with no input.
    oxwm-set-win-bg = pkgs.runCommandCC "oxwm-set-win-bg" {
      buildInputs = [ pkgs.xorg.libX11 pkgs.imlib2 ];
    } ''
      mkdir -p $out/bin
      cat << 'EOF' > main.c
      #include <X11/Xlib.h>
      #include <Imlib2.h>
      #include <signal.h>
      #include <stdio.h>
      #include <stdlib.h>
      #include <unistd.h>

      static volatile sig_atomic_t keep_running = 1;
      static void handle_sig(int sig) { (void)sig; keep_running = 0; }
      static int x_err_handler(Display *d, XErrorEvent *e) { (void)d; (void)e; return 0; }

      int main(int argc, char **argv) {
          if (argc < 3) return 1;
          Window win = (Window)strtoul(argv[1], NULL, 0);
          const char *img_path = argv[2];

          signal(SIGTERM, handle_sig);
          signal(SIGINT, handle_sig);

          Display *dpy = XOpenDisplay(NULL);
          if (!dpy) return 1;
          XSetErrorHandler(x_err_handler);

          XWindowAttributes attr;
          if (!XGetWindowAttributes(dpy, win, &attr) || attr.width <= 0 || attr.height <= 0) {
              XCloseDisplay(dpy);
              return 1;
          }

          Imlib_Image img = imlib_load_image(img_path);
          if (!img) {
              XCloseDisplay(dpy);
              return 1;
          }

          imlib_context_set_display(dpy);
          imlib_context_set_visual(attr.visual);
          imlib_context_set_colormap(attr.colormap);
          imlib_context_set_image(img);

          Pixmap pmap = XCreatePixmap(dpy, win, attr.width, attr.height, attr.depth);
          imlib_context_set_drawable(pmap);
          imlib_render_image_on_drawable_at_size(0, 0, attr.width, attr.height);
          imlib_free_image();

          GC gc = XCreateGC(dpy, win, 0, NULL);
          XSelectInput(dpy, win, ExposureMask | StructureNotifyMask | VisibilityChangeMask);
          XSetWindowBackgroundPixmap(dpy, win, pmap);
          XClearWindow(dpy, win);
          XCopyArea(dpy, pmap, win, gc, 0, 0, attr.width, attr.height, 0, 0);
          XFlush(dpy);

          int initial_Burst = 15;
          while (keep_running) {
              int need_redraw = (initial_Burst > 0);
              if (initial_Burst > 0) initial_Burst--;

              while (XPending(dpy) > 0) {
                  XEvent ev;
                  XNextEvent(dpy, &ev);
                  if (ev.type == Expose || ev.type == MapNotify || ev.type == ConfigureNotify || ev.type == VisibilityNotify) {
                      need_redraw = 1;
                  }
              }
              if (need_redraw) {
                  XSetWindowBackgroundPixmap(dpy, win, pmap);
                  XCopyArea(dpy, pmap, win, gc, 0, 0, attr.width, attr.height, 0, 0);
                  XFlush(dpy);
              }
              usleep(100000);
          }

          XFreeGC(dpy, gc);
          XFreePixmap(dpy, pmap);
          XCloseDisplay(dpy);
          return 0;
      }
      EOF
      $CC -O2 main.c -o $out/bin/oxwm-set-win-bg -lX11 -lImlib2

      cat << 'EOF' > wait_input.c
      #include <X11/Xlib.h>
      #include <string.h>
      #include <stdlib.h>
      #include <time.h>
      #include <unistd.h>

      static long now_ms(void) {
          struct timespec ts;
          clock_gettime(CLOCK_MONOTONIC, &ts);
          return (long)ts.tv_sec * 1000L + (long)(ts.tv_nsec / 1000000L);
      }

      int main(int argc, char **argv) {
          long timeout_ms = (argc > 1) ? atol(argv[1]) : 60000;
          Display *dpy = XOpenDisplay(NULL);
          if (!dpy) {
              usleep((useconds_t)(timeout_ms > 60000 ? 60000 : timeout_ms) * 1000);
              return 1;
          }
          Window root = DefaultRootWindow(dpy);

          Window r_ret, c_ret;
          int rx0 = 0, ry0 = 0, wx, wy;
          unsigned int mask0 = 0;
          char last_keys[32], keys[32];

          XQueryPointer(dpy, root, &r_ret, &c_ret, &rx0, &ry0, &wx, &wy, &mask0);
          XQueryKeymap(dpy, last_keys);

          long start_ms = now_ms();
          const unsigned int btn_mask = Button1Mask | Button2Mask | Button3Mask | Button4Mask | Button5Mask;

          while ((now_ms() - start_ms) < timeout_ms) {
              usleep(80 * 1000);

              int rx = 0, ry = 0;
              unsigned int mask = 0;
              XQueryPointer(dpy, root, &r_ret, &c_ret, &rx, &ry, &wx, &wy, &mask);
              XQueryKeymap(dpy, keys);

              /* Trigger on pointer movement (>= 2px) or new mouse button press */
              if (abs(rx - rx0) >= 2 || abs(ry - ry0) >= 2 || (((mask & ~mask0) & btn_mask) != 0)) {
                  XCloseDisplay(dpy);
                  return 0;
              }

              /* Trigger only on a new key PRESS (0 -> 1 transition), ignoring key releases */
              for (int i = 0; i < 32; i++) {
                  if (((unsigned char)keys[i] & ~(unsigned char)last_keys[i]) != 0) {
                      XCloseDisplay(dpy);
                      return 0;
                  }
                  last_keys[i] = keys[i];
              }
              mask0 = mask;
          }
          XCloseDisplay(dpy);
          return 1; /* Full timeout_ms elapsed on CLOCK_MONOTONIC with zero movement/keypress */
      }
      EOF
      $CC -O2 wait_input.c -o $out/bin/oxwm-wait-input -lX11
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

      # Dynamically theme the lockscreen auth box to match active matugen Base16 palette
      if [ -f "$HOME/.cache/matugen/colors-lock.sh" ]; then
        . "$HOME/.cache/matugen/colors-lock.sh"
        export XSECURELOCK_BACKGROUND_COLOR="''${background:-#1a1b26}"
        export XSECURELOCK_AUTH_BACKGROUND_COLOR="''${auth_background:-#24283b}"
        export XSECURELOCK_AUTH_FOREGROUND_COLOR="''${foreground:-#c0caf5}"
        export XSECURELOCK_AUTH_WARNING_COLOR="''${warning:-#f7768e}"
        export XSECURELOCK_DIM_COLOR="''${dim:-#1a1b26}"
      fi

      # Ensure ~/.cache/matugen/lock-wallpaper.png is up-to-date with current wallpaper & frost settings
      if [ -x "$HOME/nixos-dotfiles/scripts/theme-switch.sh" ]; then
        "$HOME/nixos-dotfiles/scripts/theme-switch.sh" --frost-only "''${wallpaper:-}" 2>/dev/null || true
      fi

      /run/current-system/sw/bin/oxwm-lock-dismiss || true

      exec xsecurelock
    '';

    # Hybrid xsecurelock saver module:
    #  - Immediately paints the pre-rendered dual_kawase frosted wallpaper
    #    onto $XSCREENSAVER_WINDOW's X11 background_pixmap via oxwm-set-win-bg.
    #  - Waits for 60s of continuous inactivity via xsecurelock's event-driven
    #    until_nonidle helper before launching saver_xscreensaver.
    #  - On any mouse movement or keypress, immediately stops the xscreensaver
    #    hack, repaints the frosted wallpaper, and sends SIGUSR2 to xsecurelock
    #    so the Base16-themed auth_x11 password prompt opens immediately.
    oxwm-saver-hybrid = pkgs.writeShellScriptBin "saver_oxwm-hybrid" ''
      ${lockEnv}
      [ -n "''${XSCREENSAVER_WINDOW:-}" ] || exec ${pkgs.coreutils}/bin/sleep infinity

      FROSTED_IMG="$HOME/.cache/matugen/lock-wallpaper.png"
      [ -f "$FROSTED_IMG" ] || FROSTED_IMG="${lockImage}"

      IDLE_LIMIT="''${XSECURELOCK_SAVER_IDLE_TIMEOUT:-60}"
      WAIT_INPUT="${oxwm-set-win-bg}/bin/oxwm-wait-input"
      BG_PID=""
      SAVER_PID=""
      WAIT_PID=""

      stop_bg() {
        if [ -n "$BG_PID" ] && kill -0 "$BG_PID" 2>/dev/null; then
          kill -TERM -- "-$BG_PID" 2>/dev/null || kill -TERM "$BG_PID" 2>/dev/null || true
          wait "$BG_PID" 2>/dev/null || true
        fi
        BG_PID=""
      }

      paint_frosted() {
        stop_bg
        if [ -f "$FROSTED_IMG" ]; then
          ${pkgs.util-linux}/bin/setsid sh -c '
            ${oxwm-set-win-bg}/bin/oxwm-set-win-bg "$1" "$2" || \
            exec ${pkgs.mpv}/bin/mpv \
              --really-quiet --no-config --no-osc --no-osd-bar \
              --no-input-default-bindings --vo=x11 --ao=null \
              --no-audio --hwdec=no --wid="$1" \
              --image-display-duration=inf "$2"
          ' _ "$XSCREENSAVER_WINDOW" "$FROSTED_IMG" &
          BG_PID=$!
        fi
      }

      stop_hack() {
        if [ -n "$SAVER_PID" ] && kill -0 "$SAVER_PID" 2>/dev/null; then
          kill -TERM -- "-$SAVER_PID" 2>/dev/null || kill -TERM "$SAVER_PID" 2>/dev/null || true
          wait "$SAVER_PID" 2>/dev/null || true
        fi
        SAVER_PID=""
      }

      stop_wait() {
        if [ -n "$WAIT_PID" ] && kill -0 "$WAIT_PID" 2>/dev/null; then
          kill -TERM "$WAIT_PID" 2>/dev/null || true
          wait "$WAIT_PID" 2>/dev/null || true
        fi
        WAIT_PID=""
      }

      cleanup() {
        stop_wait
        stop_hack
        stop_bg
        exit 0
      }
      trap cleanup TERM INT
      trap 'stop_wait; stop_hack; paint_frosted' USR1

      paint_frosted
      # Brief settling delay so key-release from Super+Shift+L doesn't immediately re-trigger wake
      ${pkgs.coreutils}/bin/sleep 0.35

      while :; do
        # 1. If auth_x11 is currently open, wait until it closes before starting the 60s countdown
        while ${pkgs.procps}/bin/pgrep -u "$USER" -x auth_x11 >/dev/null 2>&1; do
          ${pkgs.coreutils}/bin/sleep 0.3
        done

        # 2. Wait for 60s of continuous inactivity on the frosted wallpaper.
        #    oxwm-wait-input returns 0 on any mouse move or keypress, 1 if full 60s elapses.
        "$WAIT_INPUT" "$((IDLE_LIMIT * 1000))" &
        WAIT_PID=$!
        if wait "$WAIT_PID"; then
          WAIT_PID=""
          # Movement or keypress occurred while on frosted wallpaper: summon auth_x11 prompt
          ${pkgs.procps}/bin/pkill -u "$USER" -USR2 -x xsecurelock 2>/dev/null || true
          ${pkgs.coreutils}/bin/sleep 0.25
          continue
        fi
        WAIT_PID=""

        # 3. 60s of inactivity reached: free frosted pixmap and launch xscreensaver hack
        stop_bg
        ${pkgs.util-linux}/bin/setsid ${pkgs.xsecurelock}/libexec/xsecurelock/saver_xscreensaver &
        SAVER_PID=$!

        # 4. Block until ANY mouse movement or keypress is detected (up to 24h)
        "$WAIT_INPUT" 86400000 &
        WAIT_PID=$!
        wait "$WAIT_PID" || true
        WAIT_PID=""

        # 5. Movement/input detected! Stop xscreensaver, repaint frosted wallpaper, and pop up auth_x11
        stop_hack
        paint_frosted
        ${pkgs.procps}/bin/pkill -u "$USER" -USR2 -x xsecurelock 2>/dev/null || true
        ${pkgs.coreutils}/bin/sleep 0.25
      done
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

      # Repaint wallpaper after rate switch adhering to active theme-switch wallpaper
      if [ -f "/home/smalldog/.fehbg" ]; then
        ${pkgs.su}/bin/su - smalldog -c "DISPLAY=:0 XAUTHORITY=/home/smalldog/.Xauthority /home/smalldog/.fehbg" 2>/dev/null || true
      fi
    '';
    in

 
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];



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
    windowManager.awesome.enable = true;
    windowManager.oxwm.enable = true;

    videoDrivers = [ "nvidia" ];
    dpi = 144; # 150% scaling (96 is default 100%
    # This avoids the xrandr issue with oxwm, keep this until oxwm fixes it
    displayManager.sessionCommands = ''
      # Export Qt platform theme so all X11 GUI apps follow qt5ct / qt6ct Material You palette
      export QT_QPA_PLATFORMTHEME=qt5ct

      # Allow local root to interact with X11 (required for systemd battery/AC hooks)
      ${pkgs.xhost}/bin/xhost +SI:localuser:root || true

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

  # Login manager: SDDM with SilentSDDM and dynamic Matugen integration
  services.xserver.displayManager.lightdm.enable = false;

  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm;
    theme = "silent";
    extraPackages = with pkgs; [
      silentSDDMTheme
      kdePackages.qtsvg
      kdePackages.qtmultimedia
      kdePackages.qtvirtualkeyboard
      kdePackages.qt5compat
    ];
    settings = {
      General = {
        GreeterEnvironment = "QML2_IMPORT_PATH=${silentSDDMTheme}/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard";
        InputMethod = "qtvirtualkeyboard";
      };
    };
  };

  # Shared cache for Matugen SilentSDDM template and wallpaper (accessible by SDDM and writable by smalldog)
  systemd.tmpfiles.rules = [
    "d /var/cache/matugen-sddm 0755 smalldog users -"
  ];

  # Seed initial fallback wallpaper and configuration if /var/cache/matugen-sddm is empty
  system.activationScripts.sddm-matugen-init.text = ''
    mkdir -p /var/cache/matugen-sddm
    if [ ! -f /var/cache/matugen-sddm/wallpaper.png ]; then
      cp -f ${defaultSddmWallpaper} /var/cache/matugen-sddm/wallpaper.png 2>/dev/null || true
    fi
    if [ -f /home/smalldog/.cache/matugen/silent.conf ]; then
      cp -f /home/smalldog/.cache/matugen/silent.conf /var/cache/matugen-sddm/silent.conf 2>/dev/null || true
    elif [ ! -f /var/cache/matugen-sddm/silent.conf ]; then
      cp -f ${silentSDDMTheme}/share/sddm/themes/silent/configs/default.conf /var/cache/matugen-sddm/silent.conf 2>/dev/null || true
      sed -i 's|background = .*|background = "matugen.png"|g' /var/cache/matugen-sddm/silent.conf 2>/dev/null || true
    fi
    chmod 755 /var/cache/matugen-sddm
    chmod 644 /var/cache/matugen-sddm/* 2>/dev/null || true
    chown -R smalldog:users /var/cache/matugen-sddm 2>/dev/null || true
  '';

  



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
    silentSDDMTheme
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    featherpad
    git
    brightnessctl
    picom
    oxwm
    feh
    mpv
    # terminal file manager
    yazi
    ripdrag
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
    imagemagick
    glib
    oxwm-lock-warn
    oxwm-lock-dismiss
    oxwm-lock
    oxwm-saver-hybrid
    oxwm-set-win-bg
    oxwm-battery-rate
    psmisc
    jq
    # legion tools
    lenovo-legion
    openrgb
    lm_sensors
    # manage app images (ankiengine)
    gearlever
    # system-wide icon theme
    papirus-icon-theme
  ];

  programs.yazi = {
    plugins = {
      clipboard = pkgs.yaziPlugins.clipboard;
    };
  };

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
      ${pkgs.util-linux}/bin/rfkill block bluetooth || true

      ${pkgs.systemd}/bin/systemctl --no-block stop \
        bluetooth.service \
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
      ${pkgs.util-linux}/bin/rfkill unblock bluetooth || true

      ${pkgs.systemd}/bin/systemctl --no-block start \
        bluetooth.service \
        syncthing.service \
        tailscaled.service || true

      DISPLAY=:0 ${oxwm-battery-rate}/bin/oxwm-battery-rate 165
    '';
  };

  # Ensure Powertop's auto-tune doesn't force sleep on input or audio devices at boot
  systemd.services.powertop.postStart = ''
    for dev in /sys/bus/usb/devices/*; do
      if [ -f "$dev/power/control" ]; then
        # Class 03 = HID (keyboards/mice), Class 01 = Audio (Apple dongle/DACs)
        if ${pkgs.gnugrep}/bin/grep -rq -E '^(03|01)$' "$dev"/*/bInterfaceClass 2>/dev/null; then
          echo on > "$dev/power/control"
        fi
      fi
    done
  '';

  services.udev.extraRules = ''
    # ITE Tech Lenovo Legion RGB Controller
    SUBSYSTEM=="usb", ATTR{idVendor}=="048d", MODE="0666"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="048d", MODE="0666"

    # --- USB Autosuspend Prevention ---
    # Disable autosuspend on plug-in for HID devices (Keyboards, Mice)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="03", TEST=="../power/control", ATTR{../power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="03", TEST=="power/control", ATTR{power/control}="on"

    # Disable autosuspend for USB Audio (Apple 3.5mm dongle / DACs)
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="01", TEST=="../power/control", ATTR{../power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{bInterfaceClass}=="01", TEST=="power/control", ATTR{power/control}="on"

    # --- Battery / AC Triggers ---
    # Battery mode: ONLY trigger on Mains wall disconnect (ignores USB-C dongles)
    ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", \
      RUN+="${pkgs.systemd}/bin/systemctl --no-block start battery-mode.service", \
      RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver", \
      RUN+="${pkgs.lenovo-legion}/bin/legion_cli quiet"

    # AC mode: ONLY trigger on Mains wall connect (ignores USB-C dongles)
    ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", \
      RUN+="${pkgs.systemd}/bin/systemctl --no-block start ac-mode.service", \
      RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance", \
      RUN+="${pkgs.lenovo-legion}/bin/legion_cli balanced"
  '';

  environment.sessionVariables = {
    MOZ_X11_EGL = "1";                 # Critical for good X11 performance + VA-API
    MOZ_ENABLE_WAYLAND = "0";          # Force X11 path under OXWM
    LIBVA_DRIVER_NAME = "iHD";    # Explicit Mesa VA-API driver
    QT_QPA_PLATFORMTHEME = "qt5ct";    # Qt5 & Qt6 apps follow qt5ct/qt6ct Material You palette
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

  # Enable dconf service for declarative GSettings/Dconf and portal integration
  programs.dconf.enable = true;

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

  # Prevent xss-lock from hitting StartLimitBurst during the 2s X11 sessionCommands delay
  systemd.user.services.xss-lock = {
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig.RestartSec = 2;
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
