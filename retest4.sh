#!/usr/bin/bash
###run this script with sudo -E -s ./retest4.sh

# net_dir=/etc/netplan
net_dir=$(pwd)
# net_file="$net_dir/01-$POINT-dhcp4-$DHCP4.yaml"
net_file="$net_dir"/01-config.yaml

this_dir_path="$(dirname "$(realpath "$0")")"
this_config="$this_dir_path/retest4.sh"

RC='\e[0m'
# RV='\u001b[7m'
RED='\e[31m'
# YELLOW='\e[33m'
GREEN='\e[32m'
GREEN2='[32;1m'
WHITE='[37;1m'
BLUE='[34;1m'

if [ -f "$KEYSDIR/keysnet" ]; then
	command source "$KEYSDIR/keysnet"
else
	echo "keys file not found"
	exit 1
fi

if [ "$HOSTNAME" = vaio ]; then
	radio_adapter=wlp7s0
	# lan_adapter=enp2s0
	ip=9
elif [ "$HOSTNAME" = pcRU ]; then
	radio_adapter=wlx60e32716669c
	lan_adapter=enp2s0
	ip=27
else
	"$this_dir_path"/check_adapters.sh
	radio_adapter=$lan_adapter
	lan_adapter=$radio_adapter
fi

renderer=("NetworkManager" "networkd")
interface=("wifis" "ethernets")
adapter=("$radio_adapter" "$lan_adapter")
dhcp4_ref=("true" "no")
var_routes=("1" "0")

##########################
### Don't move this    ###
##########################
RENDERER="${renderer[0]}"
INTERFACE="${interface[0]}"
ADAPTER="${adapter[0]}"
DHCP4="${dhcp4_ref[0]}"
VAR_ROUTES="${var_routes[0]}"
POINT=$wan_point3
PASS_POINT=$wan_pass_point3
##########################
#####   51 -57 !!!  ######
##########################

# for i in "$@"; do
# 	case $i in
# 	--point=*) #wan_point{1,2,3}
# 		POINT="${i:8}"
# 		;;
# 	--pass=*) #wan_pass_point{1,2,3}
# 		PASS_POINT="${i:7}"
# 		;;
# 	esac
# done

for i in "$@"; do
	case $i in
	--point=*) #1,2,3
		eval POINT=\$wan_point"${i:8}"
		eval PASS_POINT=\$wan_pass_point"${i:8}"
		;;
	--dhcp=no)
		DHCP4="${dhcp4_ref[0]}"
		;;
	--int=wi*)
		INTERFACE="${interface[0]}"
		;;
	--int=eth*)
		INTERFACE="${interface[1]}"
		;;
	esac
done

if [ "$INTERFACE" = "wifis" ]; then
	ADAPTER=$radio_adapter
elif [ "$INTERFACE" = "ethernets" ]; then
	ADAPTER=$lan_adapter
fi

if [ "$POINT" = "$wan_point1" ]; then
	VAR_ROUTES=1
elif [ "$POINT" = "$wan_point2" ]; then
	VAR_ROUTES=0
fi

# if [ "$DHCP4" = "true" ]; then
# 	DHCP4=true
# else
# 	DHCP4=no
# fi

dhcp4_addresses=[192.168."${VAR_ROUTES}".$ip/24]
routes_via=192.168."${VAR_ROUTES}".1
# nameserv_addr_def=[8.8.8.8,8.8.4.4]
nameserv_addr=[192.168."${VAR_ROUTES}".1,8.8.8.8]

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
	up() {
		echo_f
		dhcp4_stat
	}
fi

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
	netplan apply
	sleep 1
	whatsmyip
	;;
"a")
	# cat -e "$KEYSDIR/keysnet"
	echo -e "\u001b${GREEN} Setting up point...${RC}"

	count=0
	for p in $wan_point{1,2,3}; do
		POINT="$p"
		count="$(("$count" + 1))"
		echo -e "  \u001b${BLUE} Press $count for $POINT connecting ${RC} "
	done

	echo -e "  \u001b${BLUE} Press s for scan wi-fi points ${RC} "
	echo -e "  \u001b${RED} (x) Anything else to exit ${RC}"
	read -r op

	case $op in
	*[0-9]*)
		sed -i "56 s/POINT=\$wan_point./POINT=\$wan_point$op/g" "$this_config"
		sed -i "57 s/PASS_POINT=\$wan_pass_point./PASS_POINT=\$wan_pass_point$op/g" "$this_config"
		"$this_config"
		;;
	"s")
		echo "scan wi-fi point"
		count=0
		num_point=()
		points=$("$this_dir_path"/bin/wifi_list.sh)
		for p in $points; do
			count="$(("$count" + 1))"
			point="$p"
			num_point+=("$point")
			echo -e "  \u001b${BLUE} Press $count for $point connecting ${RC} "
			# echo -e "${num_point[(("$count" - 1))]}"
		done
		read -r pnt

		case $pnt in
		*[0-9]*)
			echo -e "point is ${num_point[(($pnt - 1))]}"

			;;
		esac

		echo -e "  \u001b${RED} (x) Anything else to exit ${RC}"
		;;

	'' | *[!0-9]*)
		echo "bad option"
		;;
	esac
	;;

"d")
	echo -e "\u001b${GREEN} Setting up dhcp4...${RC}"
	if [ "$DHCP4" = "true" ]; then
		sed -i '54 s/DHCP4=\"\${dhcp4_ref\[0\]\}\"/DHCP4="${dhcp4_ref[1]}"/g' "$this_config"
	elif [ "$DHCP4" = "no" ]; then
		sed -i '54 s/DHCP4=\"\${dhcp4_ref\[1\]\}\"/DHCP4="${dhcp4_ref[0]}"/g' "$this_config"
	fi
	"$this_config"
	;;

"i")
	echo -e "\u001b${GREEN} Setting up interface...${RC}"
	if [ "$INTERFACE" = "wifis" ]; then
		sed -i '52 s/INTERFACE=\"\${interface\[0\]\}\"/INTERFACE="${interface[1]}"/g' "$this_config"
	elif [ "$INTERFACE" = "ethernets" ]; then
		sed -i '52 s/INTERFACE=\"\${interface\[1\]\}\"/INTERFACE="${interface[0]}"/g' "$this_config"
	fi
	"$this_config"
	;;

x)
	echo -e "\u001b${GREEN} Invalid option entered, Bye! ${RC}"
	exit 0
	;;
esac

# exit 0

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

#run this script with sudo -E -s ./netplan.sh.sh
