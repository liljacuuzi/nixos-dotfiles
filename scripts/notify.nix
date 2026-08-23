{ config, pkgs, ... }:

let
  # Volume notification package
  volume-notify = pkgs.writeShellApplication {
    name = "volume-notify";
    runtimeInputs = with pkgs; [
      wireplumber
      gawk
      gnugrep
      libnotify
      coreutils
    ];
    text = ''
      # Throttle: ignore calls closer than ~90 ms
      state="/tmp/volume-notify.throttle"
      now=$(date +%s%3N)
      if [ -f "$state" ]; then
        last=$(cat "$state")
        if [ $((now - last)) -lt 90 ]; then
          exit 0
        fi
      fi
      echo "$now" > "$state"

      case "''${1:-}" in
        up)
          wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
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
      # Throttle: ignore calls closer than ~90 ms
      state="/tmp/brightness-notify.throttle"
      now=$(date +%s%3N)
      if [ -f "$state" ]; then
        last=$(cat "$state")
        if [ $((now - last)) -lt 90 ]; then
          exit 0
        fi
      fi
      echo "$now" > "$state"

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

  # Opacity notification package
  opacity-notify = pkgs.writeShellApplication {
    name = "opacity-notify";
    runtimeInputs = with pkgs; [
      picom
      libnotify
      xorg.xprop
      gawk
      coreutils
    ];
    text = ''
      # Throttle: ignore calls closer than ~90 ms
      state="/tmp/opacity-notify.throttle"
      now=$(date +%s%3N)
      if [ -f "$state" ]; then
        last=$(cat "$state")
        if [ $((now - last)) -lt 90 ]; then
          exit 0
        fi
      fi
      echo "$now" > "$state"

      # Identify the active window ID
      win_id=$(xprop -root _NET_ACTIVE_WINDOW 2>/dev/null | awk '{print $NF}')
      if [ -z "$win_id" ] || [ "$win_id" = "0x0" ]; then
        state_file="/tmp/opacity_default"
      else
        state_file="/tmp/opacity_''${win_id}"
      fi

      # Read saved opacity state or default to 100%
      if [ -f "$state_file" ]; then
        curr=$(cat "$state_file")
      else
        curr=100
      fi

      # Ensure valid integer format
      curr="''${curr//[!0-9]/}"
      if [ -z "$curr" ]; then
        curr=100
      fi

      case "''${1:-}" in
        up)
          new_opacity=$((curr + 5))
          if [ "$new_opacity" -gt 100 ]; then
            new_opacity=100
          fi
          ;;
        down)
          new_opacity=$((curr - 5))
          if [ "$new_opacity" -lt 10 ]; then
            new_opacity=10
          fi
          ;;
        *)
          echo "Usage: opacity-notify {up|down}"
          exit 1
          ;;
      esac

      # Save state for the current active window
      echo "$new_opacity" > "$state_file"

      # Apply explicit opacity percentage
      picom-trans -c "$new_opacity"

      # Send notification to Dunst
      notify-send \
        -h string:x-dunst-stack-tag:opacity \
        -h int:value:"$new_opacity" \
        "Opacity" "''${new_opacity}%"
    '';
  };
in
{
  # Add binaries to user PATH
  home.packages = [
    volume-notify
    brightness-notify
    opacity-notify
  ];
}
