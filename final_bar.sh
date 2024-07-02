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

# Precompute static parts of the output
CPU_PREFIX='^c$black^ ^b$green^ CPU ^c$white^^b$grey^ '
MEM_PREFIX='^c$blue^^b$black^   ^c$blue^'
NET_ON='^c$black^ ^b$blue^ 󰤨 ^d^ ^c$blue^On'
NET_OFF='^c$black^ ^b$blue^ 󰤭 ^d^ ^c$blue^Off'
DATE_PREFIX='^c$black^ ^b$darkblue^   ^c$black^^b$blue^ '
TIME_PREFIX='^c$black^ ^b$darkblue^ 󱑆  ^c$black^^b$blue^ '

# Initialize variables
updates=''
net_status="$NET_OFF"
last_update_check=0
last_net_check=0
last_date_check=0
last_cpu_check=0
last_internet_check=0
mem_total=0
date_time=''
cpu_temp=''
internet_status="$NET_OFF"

# Read memory information
while read -r line; do
    case $line in
        MemTotal:*) mem_total=${line#MemTotal:}; mem_total=${mem_total%%kB*}; mem_total=${mem_total## }; break;;
    esac
done < /proc/meminfo

get_cpu_temp() {
    if [ -n "$CPU_ZONE" ]; then
        if [ $((SECONDS - last_cpu_check)) -ge 5 ]; then
            cpu_temp="$(printf '%s%d°C' "$CPU_PREFIX" "$(( $(cat "$CPU_ZONE") / 1000 ))")"
            last_cpu_check=$SECONDS
        fi
        printf '%s' "$cpu_temp"
    else
        printf '^c$black^ ^b$red^ CPU Temp Unavailable'
    fi
}

get_pkg_updates() {
    updates=$(apk -s upgrade 2>/dev/null | grep -c ' -> ')
    if [ "$updates" -eq 0 ]; then
        updates='  ^c$green^    Fully Updated'
    else
        updates='  ^c$green^    $updates updates'
    fi
}

get_mem_usage() {
    local available
    while read -r line; do
        case $line in
            MemAvailable:*) available=${line#MemAvailable:}; available=${available%%kB*}; available=${available## }; break;;
        esac
    done < /proc/meminfo
    used=$(((mem_total - available) / 1024))  # Convert kB to MB
    percent=$((used * 100 / (mem_total / 1024)))
    printf '%s%dM (%d%%)' "$MEM_PREFIX" "$used" "$percent"
}

get_internet_status() {
    if [ $((SECONDS - last_internet_check)) -ge 30 ]; then
        if grep -q '^default' /proc/net/route; then
            internet_status="$NET_ON"
        else
            internet_status="$NET_OFF"
        fi
        last_internet_check=$SECONDS
    fi
    printf '%s' "$internet_status"
}

update_date_time() {
    date_time="$DATE_PREFIX$(date '+%A - %b %d %Y')  $TIME_PREFIX$(date '+%I:%M:%S')  "
}

# Constants
UPDATE_INTERVAL=7200  # Check for updates every 2 hours
NET_INTERVAL=60       # Check internet every minute
DATE_INTERVAL=60      # Update date every minute

# Main loop
while true; do
    # Check for updates
    if [ $((SECONDS - last_update_check)) -ge $UPDATE_INTERVAL ]; then
        get_pkg_updates &
        last_update_check=$SECONDS
    fi

    # Check internet
    if [ $((SECONDS - last_net_check)) -ge $NET_INTERVAL ]; then
        get_internet_status &
        last_net_check=$SECONDS
    fi

    # Update date and time
    if [ $((SECONDS - last_date_check)) -ge $DATE_INTERVAL ]; then
        update_date_time &
        last_date_check=$SECONDS
    fi

    # Build status string
    status="$updates $(get_cpu_temp) $(get_mem_usage) $(get_internet_status) $date_time"

    # Set root window name
    xsetroot -name "$status"

    sleep 1
done
