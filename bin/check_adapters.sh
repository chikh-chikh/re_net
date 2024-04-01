#!/bin/bash

wan_list=()
lan_list=()

case $@ in
--verbose | -v)
	v=1
	;;
esac

for w in $(command ls /sys/class/net | grep -Ev "^lo$"); do
	if [ -d "/sys/class/net/$w/wireless" ]; then
		if [ "$v" = 1 ]; then
			echo radio_adapter="$w"
			echo "use $w"
		fi
		wan_list+=("$w")
	fi
	#подключен ли физический кабель к порту 0/1 и включен ли интерфейс up/down
  #[ ! -f /sys/class/net/"$w"/brforward ] exclude docker ???
	if [ -f /sys/class/net/"$w"/carrier ] && [ -f /sys/class/net/"$w"/operstate ] &&
		[ ! -d /sys/class/net/"$w"/wireless ] && [ ! -f /sys/class/net/"$w"/brforward ]; then
		if grep -q "1" /sys/class/net/"$w"/carrier && grep -q "down" /sys/class/net/"$w"/operstate; then
			if [ "$v" = 1 ]; then
				echo lan_adapter="$w"
				echo "use $w, is free"
			fi
			lan_list+=("$w")
		elif grep -q "up" /sys/class/net/"$w"/operstate; then
			if [ "$v" = 1 ]; then
				echo lan_adapter="$w"
				echo "use $w, but it busy"
			fi
			lan_list+=("$w")
		elif grep -q "0" /sys/class/net/"$w"/carrier; then
			if [ "$v" = 1 ]; then
				echo lan_adapter="$w"
				echo "use $w"
				echo "please, connect cable to $w interface"
			fi
			lan_list+=("$w")

			#  if grep -q '[^[:space:]]' "/sys/class/net/$w/carrier" && grep -q "down" /sys/class/net/"$w"/opesrstate; then
			# echo "interface $w is down"
			# echo "upping $w: ip link set $w up"
			#    break
			# else
			# echo "lan_adapter is undefined"
		fi
	elif [ -f /sys/class/net/"$w"/brforward ]; then
		if [ "$v" = 1 ]; then
			echo docker_net="$w"
		fi
		docker_list+=("$w")
	fi
done

# echo -e "${lan_list[*]}"
# echo -e "${wan_list[*]}"

# echo -e "$radio_adapter"
# echo -e "$lan_adapter"

# export lan_list
# export wan_list
