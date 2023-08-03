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
dhcp4=0 #1=true/0=no

if [ "$HOSTNAME" = vaio ]; then
	radio_adapter=wlp7s0
	port=9
elif [ "$HOSTNAME" = pcRU ]; then
	radio_adapter=wlx60e32716669c
	port=27
fi

echo_f() {
	echo "network:                               "
	echo "  version: 2                           "
	echo "  renderer: $renderer_N                "
	echo "  wifis:                               "
	echo "    $radio_adapter:                         "
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

if [ $name_point == 1 ]; then
	wan_pt=$wan_point1
	wan_pass=$wan_pass_point1
	var_routes=1
fi

if [ $name_point == 2 ]; then
	wan_pt=$wan_point2
	wan_pass=$wan_pass_point2
	var_routes=0
	# wan_pass=wan_pass_point$name_point
fi

if [ $name_point == 3 ]; then
	wan_pt=$wan_point2
	wan_pass=$wan_pass_point3
	# var_routes=0
fi

dhcp4_addresses=[192.168.$var_routes.$port/24]
routes_via=192.168.$var_routes.1
nameserv_addr_def=[8.8.8.8,8.8.4.4]
nameserv_addr=[192.168.$var_routes.1,8.8.8.8]

if [ $dhcp4 == 1 ]; then
	dhcp4_ref=true
	echo_f
	dhcp4_f
else
	dhcp4_ref=no
	echo_f
	dhcp4_f
	dhcp4_stat
fi
