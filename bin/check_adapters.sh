#!/bin/bash

for w in $(command ls /sys/class/net | grep -Ev "^lo$"); do
	if [ -d /sys/class/net/"$w"/wireless ]; then
		radio_adapter=$w
		# echo "use $w"
	fi
	#подключен ли какой-либо физический кабель к порту 0/1 и включен ли интерфейс up/down
	if [ -f /sys/class/net/"$w"/carrier ] && [ -f /sys/class/net/"$w"/operstate ] && [ ! -d /sys/class/net/"$w"/wireless ]; then
		if grep -q "1" /sys/class/net/"$w"/carrier && grep -q "down" /sys/class/net/"$w"/operstate; then
			# echo "use $w, is free"
			lan_adapter=$w
		elif grep -q "up" /sys/class/net/"$w"/operstate; then
			lan_adapter=$w
			# echo "use $w, but it busy"
		elif grep -q "0" /sys/class/net/"$w"/carrier; then
			lan_adapter=$w
			# echo "use $w"
			# echo "please, connect cable to $w interface"
		# else
		# 	echo "lan_adapter is undefined"
		fi
	fi
done

export radio_adapter
export lan_adapter
