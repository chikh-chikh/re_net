#!/bin/bash

for w in $(command ls /sys/class/net | egrep -v "^lo$"); do
	if [ -d /sys/class/net/"$w"/wireless ]; then
		radio_adapter=$w
	fi
	#включен ли интерфейс "up/down" и подключен ли какой-либо физический кабель к порту "0/1"
	if [ -f /sys/class/net/"$w"/carrier ] && [ -f /sys/class/net/"$w"/operstate ] && [ ! -d /sys/class/net/"$w"/wireless ]; then
		if grep "1" /sys/class/net/"$w"/carrier && grep "down" /sys/class/net/"$w"/operstate; then
			echo "use $w, is free"
			lan_adapter=$w
		elif ! grep "down" /sys/class/net/"$w"/operstate; then
			echo "$w is busy"
		elif ! grep "1" /sys/class/net/"$w"/carrier; then
			echo "please, connect cable to $w interface"
		fi
	fi
done

export radio_adapter
export lan_adapter
