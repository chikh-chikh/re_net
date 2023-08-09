#!/usr/bin/bash

if [ -f "$HOME/keysnet" ]; then
	source "$HOME/keysnet"
else
	echo "keys file not found"
	exit 1
fi

name_point=3 #1,2,3
# var_routes=  #0,1
dhcp4=1 #1=true(dinamyc)/0=no(static)

interface=1 #1-wi-fi 2-lan

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

if [ "$interface" = 1 ]; then
	interf=wifis
	adapter=$radio_adapter
elif [ "$interface" = 2 ]; then
	interf=ethernets
	adapter=$lan_adapter
fi

if [ $name_point = 1 ]; then
	wan_pt=$wan_point1
	wan_pass=$wan_pass_point1
	var_routes=1
fi

if [ $name_point = 2 ]; then
	wan_pt=$wan_point2
	wan_pass=$wan_pass_point2
	var_routes=0
	# wan_pass=wan_pass_point$name_point
fi

if [ $name_point = 3 ]; then
	wan_pt=$wan_point3
	wan_pass=$wan_pass_point3
	var_routes=0
fi

if [ $dhcp4 = 1 ]; then
	dhcp4_ref=true
else
	dhcp4_ref=no
fi

dhcp4_addresses=[192.168.$var_routes.$ip/24]
routes_via=192.168.$var_routes.1
nameserv_addr_def=[8.8.8.8,8.8.4.4]
nameserv_addr=[192.168.$var_routes.1,8.8.8.8]

echo_f() {
	echo "network:                               "
	echo "  version: 2                           "
	echo "  renderer: $renderer_N                "
	echo "  $interf:                             "
	echo "    $adapter:                          "
}
wifi_dhcp() {
	echo "      access-points:                   "
	echo "        $wan_pt:                       "
	echo "          password: $wan_pass          "
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

net_dir=/etc/netplan
# net_dir=$(pwd)
# net_file=$net_dir/01-"$wan_pt"-dhcp4-"$dhcp4_ref".yaml
net_file="$net_dir"/01-config.yaml
# net_file="$net_dir"/01-config.yaml

rm -rf "$net_dir"/01-*.yaml

if [ ! -f "$net_file" ]; then
	touch "$net_file"
	# chmod 600 "$net_file"
fi

if [ $interface = 1 ]; then
	if [ $dhcp4 = 1 ]; then
		up() {
			echo_f
			wifi_dhcp
		}
	elif [ $dhcp4 = 0 ]; then
		up() {
			echo_f
			wifi_dhcp
			dhcp4_stat
		}
	fi
elif [ $interface = 2 ]; then
	up() {
		echo_f
		dhcp4_stat
	}
fi

up >"$net_file"

netplan apply

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
sleep 2

whatsmyip

#run this script with sudo -E -s ./renet.sh
