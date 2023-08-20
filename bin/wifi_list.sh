#!/bin/bash

for i in $(command ls /sys/class/net/ | egrep -v "^lo$"); do
	if which iw &>/dev/null; then
		sudo iw dev "$i" scan | grep SSID | awk '{print substr($0, index($0,$2)) }'
	fi
done 2>/dev/null | sort -u
