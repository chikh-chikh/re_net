#!/bin/bash
sudo iptables-save > iptables-docker.txt
sudo iptables-restore-translate -f iptables-docker.txt > docker.nft
