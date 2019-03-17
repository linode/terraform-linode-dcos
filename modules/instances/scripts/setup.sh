#!/usr/bin/env bash
set -e

for mod in ip_vs_sh ip_vs ip_vs_rr ip_vs_wrr nf_conntrack_ipv4; do echo $mod | sudo tee /etc/modules-load.d/$mod.conf; done

sudo systemctl disable locksmithd
sudo systemctl stop locksmithd
sudo systemctl mask locksmithd

sudo systemctl disable update-engine
sudo systemctl stop update-engine
sudo systemctl mask update-engine
sudo systemctl restart docker # Restarting docker to ensure its ready. Seems like its not during first usage.
