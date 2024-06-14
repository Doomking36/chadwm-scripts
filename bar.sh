#!/bin/dash

# ^c$var^ = fg color
# ^b$var^ = bg color

interval=0

# load colors
. ~/.config/chadwm/scripts/bar_themes/onedark

cpu() {
  cpu_val=$(grep -o "^[^ ]*" /proc/loadavg)

  # Find the correct thermal zone for CPU temperature
  for zone in /sys/class/thermal/thermal_zone*/; do
    type=$(cat "${zone}type")
    if [ "$type" = "x86_pkg_temp" ]; then
      temp=$(cat "${zone}temp")
      temp=$((temp / 1000))  # Convert millidegrees to degrees
      break
    fi
  done

  printf "^c$black^ ^b$green^ CPU"
  printf "^c$white^ ^b$grey^ $cpu_val"
  printf "^c$white^ ^b$grey^ ${temp}°C"
}

pkg_updates() {
  updates=$(apk update > /dev/null 2>&1 && apk version -l '<' | wc -l)

  if [ "$updates" -eq 0 ]; then
    printf "  ^c$green^    Fully Updated"
  else
    printf "  ^c$green^    $updates updates"
  fi
}

battery() {
  get_capacity="$(cat /sys/class/power_supply/BAT1/capacity)"
  printf "^c$blue^   $get_capacity"
}

brightness() {
  printf "^c$red^   "
  printf "^c$red^%.0f\n" $(cat /sys/class/backlight/*/brightness)
}

mem() {
  printf "^c$blue^^b$black^  "
  printf "^c$blue^ $(free -h | awk '/^Mem/ { print $3 }' | sed s/i//g)"
}

wlan() {
  case "$(cat /sys/class/net/wl*/operstate 2>/dev/null)" in
    up) printf "^c$black^ ^b$blue^ 󰤨 ^d^%s" " ^c$blue^Connected" ;;
    down) printf "^c$black^ ^b$blue^ 󰤭 ^d^%s" " ^c$blue^Disconnected" ;;
  esac
}

clock() {
  printf "^c$black^ ^b$darkblue^ 󱑆 "
  printf "^c$black^^b$blue^ $(date '+%H:%M:%S')  "
}

while true; do
  [ $interval = 0 ] || [ $(($interval % 3600)) = 0 ] && updates=$(pkg_updates)
  interval=$((interval + 1))

  sleep 1 && xsetroot -name "$updates $(battery) $(brightness) $(cpu) $(mem) $(wlan) $(clock)"
done
