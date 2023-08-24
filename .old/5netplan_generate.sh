#!/usr/bin/bash
###run this script with sudo -E -s ./retest4.sh
net_dir=/etc/netplan
# net_dir=$(pwd)
# net_file="$net_dir/01-$POINT-dhcp4-$DHCP4.yaml"
net_file="$net_dir"/01-config.yaml
this_dir_path="$(dirname "$(realpath "$0")")"
this_config="$this_dir_path/netplan_generate.sh"

RC='\e[0m'
# RV='\u001b[7m'
RED='\e[31m'
# YELLOW='\e[33m'
GREEN='\e[32m'
GREEN2='[32;1m'
WHITE='[37;1m'
BLUE='[34;1m'

if [ -f "$keysdir/netkeys.sh" ]; then
	command source "$keysdir/netkeys.sh"
else
	keysdir="$HOME/.keysdir"
	echo "keys file not found, creating him in $keysdir"
	mkdir -p "$keysdir"
	echo -e '#!/bin/bash \ndeclare -A points' >"$keysdir/netkeys.sh"
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
	radio_adapter=$radio_adapter
	lan_adapter=$lan_adapter
fi

renderer=("NetworkManager" "networkd")
interface=("wifis" "ethernets")
adapter=("$radio_adapter" "$lan_adapter")
dhcp4_ref=("true" "no")
var_routes=("1" "0")
point=("${!points[@]}")
pass_point=("${points[@]}")
##########################
### Don't move this    ###
##########################
RENDERER="${renderer[0]}"
INTERFACE="${interface[0]}"
ADAPTER="${adapter[0]}"
DHCP4="${dhcp4_ref[0]}"
VAR_ROUTES="${var_routes[0]}"
POINT=${point[0]}
PASS_POINT=${pass_point[0]}
##########################
#####   51 -57 !!!  ######
##########################

for i in "$@"; do
	case $i in
	--scanned)
		POINT=$2
		PASS_POINT=$3
		;;
	--point=[0-9]) #1,2,3
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

if [ "$POINT" = "${point[1]}" ]; then
	VAR_ROUTES=1
elif [ "$POINT" = "${point[0]}" ]; then
	VAR_ROUTES=0
fi

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

function whatsmyip() {
	echo -n "Internal IP: "
	ifconfig "$radio_adapter" |
		grep "inet " | awk -F: '{print $1}' | awk '{print $2}'
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
	netplan apply
	sleep 1
	whatsmyip
	;;
"a")
	# cat -e "$keysdir/netkeys.sh"
	echo -e "\u001b${GREEN} Setting up point...${RC}"

	count=0
	for p in "${point[@]}"; do
		POINT="$p"
		count="$(("$count" + 1))"
		echo -e "  \u001b${BLUE} Press $count for $POINT connecting ${RC} "
	done

	echo -e "  \u001b${BLUE} Press s for scan wi-fi points ${RC} "
	echo -e "  \u001b${RED} (x) Anything else to exit ${RC}"
	read -r op

	POINT=${point[0]}
	PASS_POINT=${pass_point[0]}

	case $op in
	[0-9])
		pp="$(("$op" - 1))"
		sed -i "56 s/POINT=\${point\[.\]\}/POINT=\${point[$pp]}/g" "$this_config"
		sed -i "57 s/PASS_POINT=\${pass_point\[.\]\}/PASS_POINT=\${pass_point[$pp]}/g" "$this_config"
		"$this_config"
		;;
	"s")
		echo "scan wi-fi point"
		count=0
		num_point=()
		points=$("$this_dir_path"/bin/wifi_list.sh)
		for p in $points; do
			count="$(("$count" + 1))"
			num_point+=("$p")
			echo -e "  \u001b${BLUE} Press $count for $p connecting ${RC} "
		done
		read -r pnt

		case $pnt in
		[0-9])
			pn=${num_point[(($pnt - 1))]}
			echo -e "point is $pn"
			echo -n " Please enter the password for $pn: "
			read -r pn_pass
			# point+=(["$pn"]=$pn_pass)
			# "$this_config"
			echo -e "point[$pn]=$pn_pass" >>"$keysdir"/netkeys.sh
			"$this_config" --scanned "$pn" "$pn_pass"
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

#run this script with sudo -E -s ./netplan.sh.sh
