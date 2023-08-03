#!/usr/bin/bash

if [ -f "$HOME"/keysnet ]; then
	source "$HOME"/keysnet
else
	echo "keys file file not found"
fi

renderer_n=networkd
renderer_N=NetworkManager
lan_name=enp2s0
# radio_adapter=wlx60e32716669c

name_point=2 #1,2,3
# var_routes=  #0,1
dhcp4=1 #1=true(static)/0=no(dynamyc)

if [ "$HOSTNAME" = vaio ]; then
	radio_adapter=wlp7s0
	ip=9
elif [ "$HOSTNAME" = pcRU ]; then
	radio_adapter=wlx60e32716669c
	ip=27
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
	wan_pt=$wan_point2
	wan_pass=$wan_pass_point3
	# var_routes=0
fi

if [ $dhcp4 = 1 ]; then
	dhcp4_ref=true
else
	dhcp4_ref=false
fi

dhcp4_addresses=[192.168.$var_routes.$ip/24]
routes_via=192.168.$var_routes.1
nameserv_addr_def=[8.8.8.8,8.8.4.4]
nameserv_addr=[192.168.$var_routes.1,8.8.8.8]

echo_f() {
	echo "network:                               "
	echo "  version: 2                           "
	echo "  renderer: $renderer_N                "
	echo "  wifis:                               "
	echo "    $radio_adapter:                    "
	echo "      access-points:                   "
	echo "        $wan_pt:                       "
	echo "          password: $wan_pass          "
}
dhcp4_f() {
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
net_file=$net_dir/01-"$wan_pt"-dhcp4-"$dhcp4_ref".yaml
# net_file="$net_dir"/01-config.yaml
# net_file="$net_dir"/01-config.yaml

rm -rf "$net_dir"/01-*.yaml

if [ ! -f "$net_file" ]; then
	touch "$net_file"
	# chmod 600 "$net_file"
fi

if [ $dhcp4 = 1 ]; then
	up() {
		echo_f
		dhcp4_f
	}
else
	up() {
		echo_f
		dhcp4_f
		dhcp4_stat
	}
fi

up >"$net_file"

#run this script with sudo -E -s ./renet.sh
