#!/bin/dash

# Load colors
. ~/.config/chadwm/scripts/bar_themes/onedark

# Find the correct thermal zone for CPU temperature (only once)
for zone in /sys/class/thermal/thermal_zone*; do
    if [ "$(cat "${zone}/type")" = "x86_pkg_temp" ]; then
        CPU_ZONE="${zone}/temp"
        break
    fi
done

cpu_temp() {
    temp=$(($(cat "$CPU_ZONE") / 1000))
    printf "^c$black^ ^b$green^ CPU"
    printf "^c$white^ ^b$grey^ ${temp}°C"
}

pkg_updates() {
    updates=$(apk -s upgrade 2>/dev/null | grep -c ' -> ')
    if [ "$updates" -eq 0 ]; then
        printf "  ^c$green^    Fully Updated"
    else
        printf "  ^c$green^    $updates updates"
    fi
}

mem() {
    used=$(free -m | awk '/^Mem:/ {print $3}')
    printf "^c$blue^^b$black^   ^c$blue^${used}M"
}

internet() {
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        printf "^c$black^ ^b$blue^ 󰤨 ^d^%s" " ^c$blue^On"
    else
        printf "^c$black^ ^b$blue^ 󰤭 ^d^%s" " ^c$blue^Off"
    fi
}

date_time() {
    printf "^c$black^ ^b$darkblue^   ^c$black^^b$blue^ $(date '+%A - %b %d %Y')  "
    printf "^c$black^ ^b$darkblue^ 󱑆  ^c$black^^b$blue^ $(date '+%I:%M:%S')  "
}

interval=0
update_interval=3600  # Check for updates every hour
net_interval=60       # Check internet every minute

while true; do
    # Update components
    [ $((interval % update_interval)) -eq 0 ] && updates=$(pkg_updates)
    [ $((interval % net_interval)) -eq 0 ] && net=$(internet)
    
    cpu=$(cpu_temp)
    memory=$(mem)
    datetime=$(date_time)
    
    # Set root window name
    xsetroot -name "$updates $cpu $memory $net $datetime"
    
    sleep 1
    interval=$((interval + 1))
done
