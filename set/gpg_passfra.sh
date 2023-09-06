#!/bin/bash
# KEY_ID="$1"
# GPG_PRESET_PASS="/usr/lib/gnupg/gpg-preset-passphrase"
# KEY_GRIP=$(gpg --with-keygrip --list-secret-keys "$KEY_ID" | grep -Pom1 '^ *Keygrip += +\K.*')
# read -r -s -p "Enter passphrase to cache into gpg-agent: " PASSPHRASE
# echo
# $GPG_PRESET_PASS -c "$KEY_GRIP" <<<"$PASSPHRASE"
# # $GPG_PRESET_PASS -c "$KEY_GRIP" <<EOF
# # $PASSPHRASE
# # EOF
# RETVAL=$?
# if [ $RETVAL = 0 ]; then
# 	echo "OK"
# else
# 	echo "NOT OK"
# fi

# error() {
# 	echo >&2 "error:$*"
# }
#
# check_envvar() {
# 	local envvar_name=$1
# 	# ${!varname} indirect value in bash
# 	if [[ -z ${!envvar_name} ]]; then
# 		error "\$$envvar_name is empty"
# 		return 1
# 	fi
# }

key_id="$1"
gpg_agent_preset() {
	# local gpg_passphrase="$1"

	# authorize preset mechanism, in our context agent is not loaded yet.
	# echo allow-preset-passphrase >>~/.gnupg/gpg-agent.conf

	# echo allow-preset-passphrase >>"$GNUPGHOME"/gpg-agent.conf

	# this will start the agent ang give use keygripID
	# local keygrip=$(gpg-connect-agent -q 'keyinfo --list' /bye | awk '/KEYINFO/ { print $3 }')

	keygrip=$(gpg --with-keygrip --list-secret-keys "$key_id" | grep -Pom1 '^ *Keygrip += +\K.*')

	# output looks like
	#S KEYINFO B1A955E910AEFAAB2FAD9EADBFAA5C59AFAAF0AA D - - - P - - -
	#S KEYINFO AAA2AAE20FCB9621D22BAFEE1C0AA2B011AA6AA6 D - - - P - - -
	#OK

	read -r -s -p "Enter passphrase to cache into gpg-agent: " PASSPHRASE
	echo

	local k
	for k in $keygrip; do
		# echo "$gpg_passphrase" | /usr/lib/gnupg/gpg-preset-passphrase --preset "$k"
		echo "$PASSPHRASE" | /usr/lib/gnupg/gpg-preset-passphrase --preset "$k"
	done
}
gpg_agent_preset
