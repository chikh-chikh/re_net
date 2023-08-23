#!/usr/bin/bash
###run this script with sudo -E -s ./retest4.sh
# net_dir=/etc/netplan
net_dir=$(pwd)
# net_file="$net_dir/01-$POINT-dhcp4-$DHCP4.yaml"
net_file="$net_dir"/01-config.yaml
this_dir_path="$(dirname "$(realpath "$0")")"
this_config="$(readlink -f "$0")"
vars_file="$this_dir_path/set_vars.sh"
keys_file="$keysdir/netkeys.sh"

RC='\e[0m'
# RV='\u001b[7m'
RED='\e[31m'
# YELLOW='\e[33m'
GREEN='\e[32m'
GREEN2='[32;1m'
WHITE='[37;1m'
BLUE='[34;1m'

command source "$this_dir_path"/bin/check_adapters.sh

if [ -f "$keys_file" ]; then
	command source "$keys_file"
	echo -e "You have a "${#points[@]}" wi-fi keys"
else
	keysdir="$HOME/.keysdir"
	echo "keys file not found, creating him in $keysdir"
	mkdir -p "$keysdir"
	echo -e '#!/bin/bash \ndeclare -A points' >"$keys_file"
	command source "$keys_file"
	echo -e "You have a ${#points[@]} wi-fi keys"
fi

key_point=("${!points[@]}")
key_pass_point=("${points[@]}")
# echo -e "${key_point[@]}"
# echo -e "${key_pass_point[@]}"
renderer=("NetworkManager" "networkd")
interface=("wifis" "ethernets")
adapter=("$radio_adapter" "$lan_adapter")
dhcp4_ref=("true" "no")
var_routes=("1" "0")
local_ip=("27" "9" "10" "12")

declare -A arr
arr+=(["RENDERER"]=${renderer[0]})
arr+=(["INTERFACE"]=${interface[0]})
arr+=(["ADAPTER"]=${adapter[0]})
arr+=(["DHCP4"]=${dhcp4_ref[0]})
arr+=(["VAR_ROUTES"]=${var_routes[0]})
arr+=(["POINT"]=${key_point[0]})
arr+=(["PASS_POINT"]=${key_pass_point[0]})
arr+=(["LOCAL_IP"]=${local_ip[0]})

arr_key=("${!arr[@]}")
arr_value=("${arr[@]}")

for v in "${arr_key[@]}"; do
	eval "$v=${arr_value[$count]}" >>"$vars_file"
	count=$(("$count" + 1))
done

vars_memory=()
for a in "$@"; do
	vars_memory=("${vars_memory[@]}" "$a")
	eval "$a"
done

dhcp4_addresses=[192.168."$VAR_ROUTES"."$LOCAL_IP"/24]
routes_via=192.168."$VAR_ROUTES".1
nameserv_addr=[8.8.8.8,8.8.4.4]
# nameserv_addr=[192.168."${VAR_ROUTES}".1,8.8.8.8]

echo_f() {
	echo "network:                               "
	echo "  version: 2                           "
	echo "  renderer: $RENDERER                  "
	echo "  $INTERFACE:                          "
	echo "    $ADAPTER:                          "
}
wifi_dhcp() {
	echo "      access-points:                   "
	echo "        $POINT:                        "
	echo "          password: $PASS_POINT        "
	echo "      dhcp4: $DHCP4                    "
}
dhcp4_stat() {
	echo "      addresses: $dhcp4_addresses      "
	echo "      routes:                          "
	echo "      - to: default                    "
	echo "        via: $routes_via               "
	echo "      nameservers:                     "
	echo "        addresses: $nameserv_addr      "
}

if [ "$INTERFACE" = wifis ]; then
	ADAPTER=$radio_adapter
	if [ "$DHCP4" = true ]; then
		up() {
			echo_f
			wifi_dhcp
		}
	elif [ "$DHCP4" = no ]; then
		up() {
			echo_f
			wifi_dhcp
			dhcp4_stat
		}
	fi
elif [ "$INTERFACE" = ethernets ]; then
	ADAPTER=$lan_adapter
	up() {
		echo_f
		dhcp4_stat
	}
fi

function whatsmyip() {
	echo -n "Internal IP: "
	ifconfig "$radio_adapter" | grep "inet " | awk -F: '{print $1}' | awk '{print $2}'
	echo -n "External IP: "
	dig @resolver4.opendns.com myip.opendns.com +short
}

# Menu TUI
echo -e "\u001b${GREEN} Setting up netplan...${RC}"
echo -e "$(up)"
echo -e "  \u001b${BLUE} (y) confirm ${RC}"
echo -e "  \u001b${BLUE} (a) any points ${RC}"
echo -e "  \u001b${BLUE} (d) change dhcp ${RC}"
echo -e "  \u001b${BLUE} (i) change interface ${RC}"
echo -e "  \u001b${RED} (x) Anything else to exit ${RC}"
echo -en "\u001b${GREEN2} ==> ${RC}"

read -r option
case $option in
"y")
	# rm -rf "$net_dir"/01-*.yaml
	# if [ ! -f "$net_file" ]; then
	# 	touch "$net_file"
	# 	chmod 660 "$net_file"
	# fi
	up >"$net_file"
	# netplan apply
	sleep 1
	whatsmyip
	echo -e "\u001b${GREEN} complete${RC}"
	echo -e "\u001b${RED} Press y for remove $vars_file"
	echo -en "\u001b${GREEN2} ==> ${RC}"
	read -r nn
	case "$nn" in
	y)
		rm -f "$vars_file"
		exit
		;;
	n)
		exit
		;;
	esac
	;;

"a")
	# for l in "${list[@]}"; do
	#   eval "$l"
	# done
	#

	echo -e "\u001b${GREEN} Setting up point...${RC}"
	count=0
	for p in "${key_point[@]}"; do
		count="$(("$count" + 1))"
		echo -e "  \u001b${BLUE} Press $count for $p connecting ${RC} "
	done
	echo -e "  \u001b${BLUE} Press s for scan wi-fi points ${RC} "
	echo -e "  \u001b${RED} (x) Anything else to exit ${RC}"
	echo -en "\u001b${GREEN2} ==> ${RC}"

	read -r op
	case $op in
	[0-9])
		p_ind="$(("$op" - 1))"
		vars_memory=("${vars_memory[@]}" "POINT=${key_point[$p_ind]}" "PASS_POINT=${key_pass_point[$p_ind]}")
		"$this_config" "${vars_memory[@]}"
		;;

	"s")
		echo "scan wi-fi point"
		arr_pnt=()
		cnt=0
		list_pnts=$("$this_dir_path"/bin/wifi_list.sh)
		for ps in $list_pnts; do
			arr_pnt+=("$ps")
			cnt="$(("$cnt" + 1))"
			echo -e "\u001b${BLUE} Press $cnt for $ps connecting ${RC} "
		done

		read -r pnt
		case $pnt in
		*[0-9]*)
			num=$(("$pnt" - 1))
			pname=${arr_pnt[$num]}
			echo -n " Enter the password for $pname: "
			read -r pn_pass
			echo -e "points[$pname]=$pn_pass" >>"$keysdir/netkeys.sh"

			key_point=("${key_point[@]}" "$pname")
			key_pass_point=("${key_pass_point[@]}" "$pn_pass")

			corr_num=$(("${#key_point[@]}" - 1))

			vars_memory=("${vars_memory[@]}" "POINT=${key_point[$corr_num]}" "PASS_POINT=${key_pass_point[$corr_num]}")
			"$this_config" "${vars_memory[@]}"
			;;
		esac

		echo -e "\u001b${RED} (x) Anything else to exit ${RC}"
		echo -en "\u001b${GREEN2} ==> ${RC}"
		;;

	# '' | *[!0-9]*)
	# 	echo "\u001b${RED} bad option"
	# 	"$this_config"
	# 	;;
	esac
	;;

"d")
	echo -e "\u001b${GREEN} Setting up dhcp4...${RC}"

	if [ "$DHCP4" = "true" ]; then
		vars_memory=("${vars_memory[@]}" "DHCP4=no")
	elif [ "$DHCP4" = "no" ]; then
		vars_memory=("${vars_memory[@]}" "DHCP4=true")
	fi
	"$this_config" "${vars_memory[@]}"

	;;

"i")
	echo -e "\u001b${GREEN} Setting up interface...${RC}"
	if [ "$INTERFACE" = "wifis" ]; then
		vars_memory=("${vars_memory[@]}" "INTERFACE=ethernets")
	elif [ "$INTERFACE" = "ethernets" ]; then
		vars_memory=("${vars_memory[@]}" "INTERFACE=wifis")
	fi
	"$this_config" "${vars_memory[@]}"
	;;

x)
	echo -e "\u001b${GREEN} Invalid option entered, Bye! ${RC}"
	exit 0
	;;
esac

# exit 0

#run this script with sudo -E -s ./netplan.sh.sh
