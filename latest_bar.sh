#!/bin/dash

#^c$var^ = fg color
#^b$var^ = bg color

interval=0

#load colors
. ~/.config/chadwm/scripts/bar_themes/onedark

cpu_temp() {
  #Find the correct thermal zone for CPU temperature
  for zone in /sys/class/thermal/thermal_zone/; do
    type=$(cat "${zone}type")
    if [ "$type" = "x86_pkg_temp" ]; then
      temp=$(cat "${zone}temp")
      temp=$((temp / 1000))  # Convert millidegrees to degrees
      break
    fi
  done

  printf "^c$black^ ^b$green^ CPU"
  printf "^c$white^ ^b$grey^ ${temp}°C"
}

pkg_updates() {
  updates=$(apk -s upgrade 2>/dev/null | grep -c ' -> ')

  if [ "$updates" -eq 0 ]; then
    printf "  ^c$green^    Fully Updated"
  else
    printf "  ^c$green^    $updates updates"
  fi
}


mem() {
  printf "^c$blue^^b$black^  "
  printf "^c$blue^ $(free -h | awk '/^Mem/ { print $3 }' | sed s/i//g)"
}

internet() {
  if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    printf "^c$black^ ^b$blue^ 󰤨 ^d^%s" " ^c$blue^On"
  else
    printf "^c$black^ ^b$blue^ 󰤭 ^d^%s" " ^c$blue^Off"
  fi
}

day() {
  printf "^c$black^ ^b$darkblue^  "
  printf "^c$black^^b$blue^ $(date '+%A - %b %d %Y')  "

}

clock() {
  printf "^c$black^ ^b$darkblue^ 󱑆 "
  #printf "^c$black^^b$blue^ $(date '+%H:%M:%S')  "
  printf "^c$black^^b$blue^ $(date '+%I:%M:%S')  "

}

while true; do
  [ $interval = 0 ] || [ $(($interval % 3600)) = 0 ] && updates=$(pkg_updates)
  interval=$((interval + 1))

  sleep 1 && xsetroot -name "$updates $(cpu_temp) $(mem) $(internet) $(day) $(clock)"
done
