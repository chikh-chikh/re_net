#!/bin/bash

THIS_REPO_PATH="$(dirname "$(realpath "$0")")"
netplan_generate_config="$THIS_REPO_PATH/netplan_generate.sh"

sudo -E -s "$netplan_generate_config"
