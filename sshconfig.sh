#!/bin/bash
yellow='\u001b[33;1m'
rc='\u001b[0m'

this_dir="$(dirname "$(realpath "$0")")"

keysdir=$HOME/.keysdir
file_with_array_hosts="$keysdir/hosts.sh"
# this_config="$(readlink -f "$0")"
# ssh_config_dir=$HOME/.ssh/config.d
ssh_config_dir=$this_dir

if [ -f "$file_with_array_hosts" ]; then
	command source "$file_with_array_hosts"
	echo -e "${yellow} You have a ${#host[@]} hosts ${rc}"
else
	keysdir="$HOME/.keysdir"
	echo "${yellow} keys with hosts not found, creating him in $file_with_array_hosts ${rc}"
	mkdir -p "$keysdir"
	echo -e '#!/bin/bash \ndeclare -A host' >"$file_with_array_hosts"
fi

# git_hub_host() {
# 	echo "Host github.com"
# 	echo "  HostName github.com"
# 	echo "  User git"
# 	echo "  IdentityFile ~/.ssh/id_rsa"
# 	echo "  IdentitiesOnly yes"
# }

host_list=("${!host[@]}")
# in_on_host=("${host[@]}")

# declare -A default
# dafault[host]=""
# dafault[host_name]=""
# dafault[port]="22"
# dafault[identity_file]="$HOME/.ssh/dafault"
# dafault[identities_only]="yes"
# dafault[user]="ru"

send_f() {
	echo " Host vps"
	echo "   HostName "
	echo "   Port 22"
	echo "   IdentityFile "
	echo "   IdentitiesOnly yes"
	echo "   User ru"
	echo "   IdentitiesOnly yes"
}

for h in "${host_list[@]}"; do
	if [ "${host[$h]}" = "on" ]; then
		host_file="$ssh_config_dir/$h"
		send_f >"$host_file"
		# echo -e "$h"
	fi
done
