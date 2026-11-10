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
          -h int:value:"$vol" \
          "Volume" "$vol%" &    
      else
       # volume example (do the same pattern for the other two)
        dunstify -a "volume" -r 9991 -t 1500 -u low \
        -h string:x-dunst-stack-tag:volume \
        -h int:value:"$vol" \
        "Volume" "$vol%"
      fi
    '';
  };

  # Brightness notification package (xrandr version – hardened)
  brightness-notify = pkgs.writeShellApplication {
    name = "brightness-notify";
    runtimeInputs = with pkgs; [
      xrandr
      gawk
      gnugrep
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

      # Find the connected eDP* output (handles eDP-1, eDP-1-1, eDP1, …)
      output=$(xrandr 2>/dev/null | awk '/eDP.*connected/ {print $1; exit}')
      if [ -z "$output" ]; then
        # last-ditch fallback
        output="eDP-1"
      fi

      # Read current software brightness (0.0–1.0). Never fail the script.
      curr=$(xrandr --verbose --current 2>/dev/null | awk -v out="$output" '
        $0 ~ "^" out " " { found = 1 }
        found && /Brightness:/ { print $2; exit }
      ' || true)
      curr="''${curr:-1.0}"

      case "''${1:-}" in
        up)
          new=$(awk -v c="$curr" 'BEGIN {
            v = c + 0.05
            if (v > 1.0) v = 1.0
            printf "%.2f", v
          }')
          ;;
        down)
          new=$(awk -v c="$curr" 'BEGIN {
            v = c - 0.05
            if (v < 0.0) v = 0.0
            printf "%.2f", v
          }')
          ;;
        *)
          echo "Usage: brightness-notify {up|down}" >&2
          exit 1
          ;;
      esac

      # Apply (ignore errors so notification still fires)
      xrandr --output "$output" --brightness "$new" 2>/dev/null || true

      # Integer percent for the notification (same logic as before)
      bright=$(awk -v b="$new" 'BEGIN { print int(b * 100 + 0.5) }')

      # Exactly the same dunstify call you already had
      dunstify -a "brightness" -r 9991 -t 1500 -u low \
        -h string:x-dunst-stack-tag:brightness \
        -h int:value:"$bright" \
        "Brightness" "''${bright}%" &
    '';
  };

  # Opacity notification package
  opacity-notify = pkgs.writeShellApplication {
    name = "opacity-notify";
    runtimeInputs = with pkgs; [
      picom
      libnotify
      xprop
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
      # Identify the active window ID.
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
      dunstify -a "opacity" -r 9991 -t 1500 -u low \
        -h string:x-dunst-stack-tag:opacity \
        -h int:value:"$new_opacity" \
        "Opacity" "''${new_opacity}%" &
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
