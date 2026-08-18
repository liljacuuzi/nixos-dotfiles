{ pkgs, ... }:

let
  # Declarative script for Volume notifications
  volume-notify = pkgs.writeShellApplication {
    name = "volume-notify";

    # Automatically pulls dependencies into PATH
    runtimeInputs = with pkgs; [
      wireplumber
      gawk
      gnugrep
      libnotify
    ];

    text = ''
      case "''${1:-}" in
        up)
          wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
          ;;
        down)
          wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
          ;;
        mute)
          wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
          ;;
        *)
          echo "Usage: volume-notify {up|down|mute}"
          exit 1
          ;;
      esac

      vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
      muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o "MUTED" || true)

      if [ "$muted" = "MUTED" ]; then
        notify-send \
          -h string:x-dunst-stack-tag:volume \
          -h int:value:0 \
          "Audio" "Muted"
      else
        notify-send \
          -h string:x-dunst-stack-tag:volume \
          -h int:value:"$vol" \
          "Volume" "$vol%"
      fi
    '';
  };

  # Declarative script for Brightness notifications
  brightness-notify = pkgs.writeShellApplication {
    name = "brightness-notify";

    runtimeInputs = with pkgs; [
      brightnessctl
      coreutils
      libnotify
    ];

    text = ''
      case "''${1:-}" in
        up)
          brightnessctl set 10%+
          ;;
        down)
          brightnessctl set 10%-
          ;;
        *)
          echo "Usage: brightness-notify {up|down}"
          exit 1
          ;;
      esac

      bright=$(brightnessctl -m | cut -d, -f4 | tr -d '%')

      notify-send \
        -h string:x-dunst-stack-tag:brightness \
        -h int:value:"$bright" \
        "Brightness" "$bright%"
    '';
  };
in
{
  # Add the generated scripts to user PATH so IceWM can execute them directly
  home.packages = [
    volume-notify
    brightness-notify
  ];

  # IceWM Keybindings referencing the script binaries directly from PATH
  home.file.".icewm/keys" = {
    text = ''
      # Volume keys
      key "XF86AudioRaiseVolume" volume-notify up
      key "XF86AudioLowerVolume" volume-notify down
      key "XF86AudioMute"        volume-notify mute

      # Brightness keys
      key "XF86MonBrightnessDown" brightness-notify down
      key "XF86MonBrightnessUp"   brightness-notify up
    '';
  };
}
