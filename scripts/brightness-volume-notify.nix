{ config, pkgs, ... }:

let
  dotfilesKeysPath = "${config.home.homeDirectory}/nixos-dotfiles/config/icewm/keys";

  # Volume notification package
  volume-notify = pkgs.writeShellApplication {
    name = "volume-notify";

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

  # Brightness notification package
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
          brightnessctl set +5%
          ;;
        down)
          brightnessctl set 5%-
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
  # Add binaries to user PATH
  home.packages = [
    volume-notify
    brightness-notify
  ];

  # Targets the keys file INSIDE your nixos-dotfiles repository directory
  home.file."${dotfilesKeysPath}" = {
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
