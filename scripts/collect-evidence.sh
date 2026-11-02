#!/bin/bash
# Enregistre dans evidence/ la sortie (avec nom d'hôte et date) des commandes de vérification.
# À lancer sur le CONTRÔLEUR, depuis la racine du dépôt :  ./scripts/collect-evidence.sh
# Volontairement absents : "token issue" (jeton) et "zerotier-cli peers" (IP publiques).

source ~/admin-openrc || exit 1
mkdir -p evidence

run() { n="$1"; shift; { echo "\$ $*"; echo "# $(hostname) - $(date)"; "$@"; } > "evidence/$n.txt" 2>&1; echo "evidence/$n.txt"; }

run 01-service-list      openstack service list
run 02-endpoint-list     openstack endpoint list
run 03-image-list        openstack image list
run 04-compute-services  openstack compute service list
run 05-network-agents    openstack network agent list
run 06-hypervisors       openstack hypervisor list
run 07-cells             sudo su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
run 08-placement-check   sudo placement-status upgrade check
run 09-interfaces        ip -br a
run 10-services-actifs   systemctl is-active mariadb rabbitmq-server memcached apache2 glance-api nova-api nova-scheduler nova-conductor nova-novncproxy neutron-server

# Jour 5 : décommentez après le lancement des VM
# run 11-flavors   openstack flavor list
# run 12-networks  openstack network list
# run 13-subnets   openstack subnet list
# run 14-router    openstack router show router1
# run 15-sg-rules  openstack security group rule list lab-sg
# run 16-servers   openstack server list --long
# run 17-vm1       openstack server show vm1
# run 18-vm2       openstack server show vm2
