#!/bin/bash
PIDs=`ls /proc | grep -E "^[0-9]+$" | sort -n`

echo -e "PID\tTTY\tSTAT\tTIME\tCOMMAND"
tics=$(getconf CLK_TCK)

for PID in $PIDs; do
    PID=${PID##*/}

    if [ -d "/proc/$PID" ]; then
	if [ -e "/proc/$PID/fd/0" ]; then
	    TTY=$(readlink /proc/$PID/fd/0 | sed 's|/dev/||')
	    if [ $TTY == "null" ]; then
		TTY='?'
	    elif [[ $TTY == *"run"* ]]; then
		TTY='?'
	    fi
	fi
	if [ -e "/proc/$PID/stat" ]; then
	    read -a stat < "/proc/$PID/stat"
	    STAT=${stat[2]}
	    priority=$(awk '{print $19}' /proc/$PID/stat)
	    case $priority in
		"-20")
		    STAT="${STAT}<"
		;;
		"19")
		    STAT="${STAT}N"
		;;
	    esac
	    nssid=$(awk '/NSsid/ {print $2}' /proc/$PID/status)
	    if [ "$nssid" = "$PID" ]; then
		STAT="${STAT}s"
	    fi
	    multitr=$(find /proc/$PID/task -mindepth 1 -maxdepth 1 -type d | wc -l)
	    if [ "$multitr" != 1 ]; then
		STAT="${STAT}l"
	    fi
	    foregrnd=$(awk '{print $8}' /proc/$PID/stat)
	    if [ "$foregrnd" = "$PID" ]; then
		STAT="${STAT}+"
	    fi

	    let "CPUutil=((${stat[13]} + ${stat[14]}) / $tics)"
	    min=$(((CPUutil / 60)%60))
	    sec=$((CPUutil % 60))
	    sec=$(printf "%02d" "$sec")
	    TIME="$min":"$sec"

	    if [ -e "/proc/$PID/cmdline" ]; then
				COMMAND=$(tr -d '\0' < "/proc/$PID/cmdline")
				if [ -z "$COMMAND" ]; then
					CMD=${stat[1]}
					CMD=${CMD#(}
					CMD=${CMD%)}
				fi
			fi
		fi
	fi
	INFO_OUTPUT="$PID\t$TTY\t$STAT\t$TIME\t$COMMAND"
	echo -e "$INFO_OUTPUT"
done

