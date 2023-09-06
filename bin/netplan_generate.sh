#!/usr/bin/bash
###run this script with sudo -E -s ./retest4.sh
net_dir=/etc/netplan
# net_dir=$(pwd)
# net_file="$net_dir/01-$point-dhcp4-$dhcp4.yaml"
net_file="$net_dir"/01-config.yaml
this_dir_path="$(dirname "$(realpath "$0")")"
this_config="$(readlink -f "$0")"
keys_file="$keysdir/netkeys.sh"

# black='\u001b[30;1m'
red='\u001b[31;1m'
green='\u001b[32;1m'
yellow='\u001b[33;1m'
blue='\u001b[34;1m'
magenta='\u001b[35;1m'

reversed='\u001b[7m'
rc='\u001b[0m'

command source "$this_dir_path"/check_adapters.sh

if [ -f "$keys_file" ]; then
	command source "$keys_file"
	echo -e "${yellow} You have a ${#points[@]} wi-fi keys ${rc}"
else
	keysdir="$HOME/.keysdir"
	echo "${yellow} keys file not found, creating him in $keysdir ${rc}"
	mkdir -p "$keysdir"
	echo -e '#!/bin/bash \ndeclare -A points' >"$keys_file"
	command source "$keys_file"
	echo -e "${yellow} You have a ${#points[@]} wi-fi keys ${rc}"
fi

key_point=("${!points[@]}")
key_pass_point=("${points[@]}")
# echo -e "${key_point[@]}"
# echo -e "${key_pass_point[@]}"
renderer_list=("NetworkManager" "networkd")
interface_list=("wifis" "ethernets")
adapter_list=("$radio_adapter" "$lan_adapter")
dhcp4_list=("true" "no")
var_routes_list=("1" "0")
local_ip_list=("27" "9" "10" "12")

renderer=${renderer_list[0]}
interface=${interface_list[0]}
adapter=${adapter_list[0]}
dhcp4=${dhcp4_list[0]}
var_router=${var_routes_list[0]}
point=${key_point[0]}
pass_point=${key_pass_point[0]}
local_ip=${local_ip_list[0]}

vars_memory=()
for a in "$@"; do
	vars_memory=("${vars_memory[@]}" "$a")
	eval "$a"
done

if [ "$interface" = wifis ]; then
	adapter=$radio_adapter
elif [ "$interface" = ethernets ]; then
	adapter=$lan_adapter
fi

dhcp4_addresses=[192.168."$var_router"."$local_ip"/24]
routes_via=192.168."$var_router".1
nameserv_addr=[8.8.8.8,8.8.4.4]
# nameserv_addr=[192.168."${var_router}".1,8.8.8.8]

echo_f() {
	echo "network:"
	echo "  version: 2"
	echo "  renderer: $renderer"
	echo "  $interface:"
	echo "    $adapter:"
}
wifi_dhcp() {
	echo "      access-points:"
	echo "        $point:"
	echo "          password: $pass_point"
	echo "      dhcp4: $dhcp4"
}
dhcp4_stat() {
	echo "      addresses: $dhcp4_addresses"
	echo "      routes:"
	echo "      - to: default"
	echo "        via: $routes_via"
	echo "      nameservers:"
	echo "        addresses: $nameserv_addr"
}

if [ "$interface" = wifis ]; then
	if [ "$dhcp4" = true ]; then
		up() {
			echo_f
			wifi_dhcp
		}
	elif [ "$dhcp4" = no ]; then
		up() {
			echo_f
			wifi_dhcp
			dhcp4_stat
		}
	fi
elif [ "$interface" = ethernets ]; then
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
echo -e "${magenta}${reversed} setting up netplan ${rc}"
echo -e "$(up)"
echo -e "${blue} (y) confirm ${rc}"
echo -e "${blue} (a) any points ${rc}"
echo -e "${blue} (d) change dhcp ${rc}"
echo -e "${blue} (i) change interface ${rc}"
echo -e "${blue} (p) change local ip ${rc}"
echo -e "${red} (x) Anything else to exit ${rc}"
echo -en "${green} ==> ${rc}"

read -r option
case $option in
"y")
	# rm -rf "$net_dir"/01-*.yaml
	# if [ ! -f "$net_file" ]; then
	# 	touch "$net_file"
	# 	chmod 600 "$net_file"
	# fi
	up >"$net_file"
	netplan apply
	sleep 3
	whatsmyip
	;;

"a")
	echo -e "${magenta} setting up point ${rc}"
	count=0
	for p in "${key_point[@]}"; do
		count="$(("$count" + 1))"
		echo -e "${blue} ($count) - $p ${rc} "
	done
	echo -e "${blue} (s) - scan wi-fi points ${rc} "
	echo -e "${red} (x) - exit ${rc}"
	echo -en "${green} ==> ${rc}"

	read -r op
	case $op in
	[0-9])
		p_ind="$(("$op" - 1))"
		vars_memory=("${vars_memory[@]}" "point=${key_point[$p_ind]}" "pass_point=${key_pass_point[$p_ind]}")
		"$this_config" "${vars_memory[@]}"
		;;

	"s")
		echo -e "${magenta} scan wi-fi point ${rc}"
		arr_pnt=()
		cnt=0
		list_pnts=$("$this_dir_path"/wifi_list.sh)
		for ps in $list_pnts; do
			arr_pnt+=("$ps")
			cnt="$(("$cnt" + 1))"
			echo -e "${blue} ($cnt) - $ps ${rc} "
		done
		echo -e "${red} (x) exit ${rc}"
		echo -en "${green} ==> ${rc}"

		read -r pnt
		case $pnt in
		*[0-9]*)
			num=$(("$pnt" - 1))
			pname=${arr_pnt[$num]}
			echo -n "enter the password for $pname: "
			read -r pn_pass
			echo -e "points[$pname]=$pn_pass" >>"$keysdir/netkeys.sh"

			key_point=("${key_point[@]}" "$pname")
			key_pass_point=("${key_pass_point[@]}" "$pn_pass")

			corr_num=$(("${#key_point[@]}" - 1))

			vars_memory=("${vars_memory[@]}" "point=${key_point[$corr_num]}" "pass_point=${key_pass_point[$corr_num]}")
			"$this_config" "${vars_memory[@]}"
			;;
		esac

		echo -e "${red} (x) exit ${rc}"
		echo -en "${green} ==> ${rc}"
		;;

	# '' | *[!0-9]*)
	# 	echo "${red} bad option"
	# 	"$this_config"
	# 	;;
	esac
	;;

"d")
	if [ "$dhcp4" = "true" ]; then
		vars_memory=("${vars_memory[@]}" "dhcp4=no")
	elif [ "$dhcp4" = "no" ]; then
		vars_memory=("${vars_memory[@]}" "dhcp4=true")
	fi
	"$this_config" "${vars_memory[@]}"
	;;

"i")
	if [ "$interface" = "wifis" ]; then
		vars_memory=("${vars_memory[@]}" "interface=ethernets")
	elif [ "$interface" = "ethernets" ]; then
		vars_memory=("${vars_memory[@]}" "interface=wifis")
	fi
	"$this_config" "${vars_memory[@]}"
	;;
"p")
	sum="${#local_ip_list[@]}"
	sum_ind=$(("$sum" - 1))
	for i in "${!local_ip_list[@]}"; do
		[[ "${local_ip_list[$i]}" = "$local_ip" ]] && break
	done
	ip_ind="$i"
	if [[ "$ip_ind" -lt "$sum_ind" ]]; then
		ip_ind=$(("$ip_ind" + 1))
		vars_memory=("${vars_memory[@]}" "local_ip=${local_ip_list[$ip_ind]}")
	else
		ip_ind=0
		vars_memory=("${vars_memory[@]}" "local_ip=${local_ip_list[$ip_ind]}")
	fi
	"$this_config" "${vars_memory[@]}"
	;;

x)
	echo -e "${green} invalid option entered, bye! ${rc}"
	exit 0
	;;
esac

# exit 0

#run this script with sudo -E -s ./netplan.sh.sh
