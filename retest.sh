#!/usr/bin/bash

if [ -f "$HOME/keysnet" ]; then
	source "$HOME/keysnet"
else
	echo "keys file not found"
	exit 1
fi

renderer_n=networkd
renderer_N=NetworkManager

if [ "$HOSTNAME" = vaio ]; then
	radio_adapter=wlp7s0
	# lan_adapter=enp2s0
	ip=9
elif [ "$HOSTNAME" = pcRU ]; then
	radio_adapter=wlx60e32716669c
	lan_adapter=enp2s0
	ip=27
fi

interface=("wifis" "ethernets")
adapter=("$radio_adapter" "$lan_adapter")

point=("$wan_point1" "$wan_point2" "$wan_point3")
pass=("$wan_pass_point1" "$wan_pass_point2" "$wan_pass_point3")
var_routes=("1" "0")
dhcp4_ref=("true" "no")

echo_f() {
	echo "network:                               "
	echo "  version: 2                           "
	echo "  renderer: $renderer_N                "
	echo "  $interface:                             "
	echo "    $adapter:                          "
}
wifi_dhcp() {
	echo "      access-points:                   "
	echo "        $point:                       "
	echo "          password: $pass          "
	echo "      dhcp4: $dhcp4_ref                "
}
dhcp4_stat() {
	echo "      addresses: $dhcp4_addresses      "
	echo "      routes:                          "
	echo "      - to: default                    "
	echo "        via: $routes_via               "
	echo "      nameservers:                     "
	echo "        addresses: $nameserv_addr      "
}

# net_dir=/etc/netplan
net_dir=$(pwd)
# net_file=$net_dir/01-"$wan_pt"-dhcp4-"$dhcp4_ref".yaml
net_file="$net_dir"/01-config.yaml
# net_file="$net_dir"/01-config.yaml

# rm -rf "$net_dir"/01-*.yaml

if [ ! -f "$net_file" ]; then
	touch "$net_file"
	# chmod 600 "$net_file"
fi

# if [ $interface = 1 ]; then
# 	if [ $dhcp4 = 1 ]; then
up_wi-fi_dhcp_true() {
	interface="${interface[0]}"
	adapter="${adapter[0]}"
	point="${point[1]}"
	pass="${pass[1]}"
	var_routes="${var_routes[0]}"
	dhcp4_ref="${dhcp4_ref[0]}"

	echo_f
	wifi_dhcp
}
# elif [ $dhcp4 = 0 ]; then
up_wi-fi_dhcp_stat() {
	echo_f
	wifi_dhcp
	dhcp4_stat
}
# fi
# elif [ $interface = 2 ]; then
up_lan() {
	echo_f
	dhcp4_stat
}
# fi

dhcp4_addresses=[192.168."${var_routes[$1]}".$ip/24]
routes_via=192.168."${var_routes[$1]}".1
# nameserv_addr_def=[8.8.8.8,8.8.4.4]
nameserv_addr=[192.168."${var_routes[$1]}".1,8.8.8.8]

RC='\e[0m'
# RV='\u001b[7m'
RED='\e[31m'
# YELLOW='\e[33m'
GREEN='\e[32m'
GREEN2='[32;1m'
WHITE='[37;1m'
BLUE='[34;1m'

# Menu TUI
echo -e "\u001b${GREEN} Setting up Dotfiles...${RC}"

echo -e " \u001b${WHITE}\u001b[4mSelect an option:${RC}"
echo -e "  \u001b${BLUE} (1) wi-fi dinamyc ip ${RC}"
echo -e "  \u001b${BLUE} (2) wi-fi static ip ${RC}"
echo -e "  \u001b${BLUE} (3) lan ${RC}"
# echo -e "  \u001b${BLUE} (4)  ${RC}"
echo -e "  \u001b${RED} (*) Anything else to exit ${RC}"

echo -en "\u001b${GREEN2} ==> ${RC}"

read -r option

case $option in

"1")
	up_wi-fi_dhcp_true >"$net_file"
	;;

"2")
	up_wi-fi_dhcp_stat >"$net_file"
	;;

"3")
	up_lan >"$net_file"
	;;

# "4")
#
# 	;;
*)
	echo -e "\u001b[31;1m Invalid option entered, Bye! ${RC}"
	exit 0
	;;
esac

# exit 0

# up >"$net_file"

# netplan apply

function whatsmyip() {
	# Internal IP Lookup
	echo -n "Internal IP: "
	# ifconfig enp2s0 \
	ifconfig "$radio_adapter" |
		# grep "inet" | awk -F: '{print $2}' | awk '{print $1}'
		grep "inet " | awk -F: '{print $1}' | awk '{print $2}'
	# External IP Lookup
	echo -n "External IP: "
	# wget http://smart-ip.net/myip -O - -q
	dig @resolver4.opendns.com myip.opendns.com +short
}
# sleep 1

whatsmyip

#run this script with sudo -E -s ./renet.sh
