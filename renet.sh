#!/bin/bash

THIS_REPO_PATH="$(dirname "$(realpath "$0")")"
netplan_config="$THIS_REPO_PATH/bin/netplan.sh"

$netplan_config
