#!/bin/bash

renderer_n=networkd
renderer_N=NetworkManager
lan_name=enp2s0
dhcp4_tru=true
dhcp4_false=no
dhcp4_addresses1=[192.168.1.27/24]
dhcp4_addresses2=[192.168.0.27/24]
routes_via1=192.168.1.1
routes_via2=192.168.0.1
nameserv_addr_def=[8.8.8.8,8.8.4.4]
nameserv_addr1=[192.168.1.1,8.8.8.8]
nameserv_addr2=[192.168.0.1,8.8.8.8]

source "$HOME"/keysnet

# network:
#   version: 2
#   renderer: $renderer_N
#   wifis:
#     $wan_name:
#       access-points:
#         $wan_point2:
#           password: $wan_pass_point2
#       # dhcp4: $dhcp4_false
#
#       dhcp4: $dhcp4_false
#       addresses: $dhcp4_addresses2
#       routes:
#       - to: default
#         via: $routes_via2
#       nameservers:
#         addresses: $nameserv_addr2
#

echo_f {
echo "network:                               "     
echo "  version: 2                           "      
echo "  renderer: $renderer_N                "     
echo "  wifis:                               "   
echo "    $wan_name:                         "   
echo "      access-points:                   "   
echo "        $wan_point2:                   "   
echo "          password: $wan_pass_point2   "   
echo "                                       "       
echo "      dhcp4: $dhcp4_false              "         
echo "      addresses: $dhcp4_addresses2     "     
echo "      routes:                          "           
echo "      - to: default                    "           
echo "        via: $routes_via2              "         
echo "      nameservers:                     "         
echo "        addresses: $nameserv_addr2     "           
}

echo_f

