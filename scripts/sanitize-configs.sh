#!/bin/bash
# Copie les fichiers de configuration de CETTE machine dans configs/<nom>,
# sans commentaires, sans lignes vides et sans mot de passe.
#
# usage :  read -s LAB_PASSWORD; export LAB_PASSWORD     (saisie invisible)
#          ./scripts/sanitize-configs.sh controller      (ou compute1 / compute2)
#
# Le mot de passe n'est PAS écrit dans ce script : il est lu dans la variable
# LAB_PASSWORD pour ne jamais apparaître dans le dépôt.

DEST="configs/${1:?usage: $0 controller|compute1|compute2}"
PW="${LAB_PASSWORD:?definissez d abord LAB_PASSWORD avec : read -s LAB_PASSWORD; export LAB_PASSWORD}"
mkdir -p "$DEST"

FILES="
/etc/hosts
/etc/chrony/chrony.conf
/etc/mysql/mariadb.conf.d/99-openstack.cnf
/etc/memcached.conf
/etc/systemd/system/memcached.service.d/wait-zt.conf
/etc/systemd/system/mariadb.service.d/wait-zt.conf
/etc/keystone/keystone.conf
/etc/glance/glance-api.conf
/etc/placement/placement.conf
/etc/nova/nova.conf
/etc/nova/nova-compute.conf
/etc/neutron/neutron.conf
/etc/neutron/plugins/ml2/ml2_conf.ini
/etc/neutron/plugins/ml2/linuxbridge_agent.ini
/etc/neutron/l3_agent.ini
/etc/neutron/dhcp_agent.ini
/etc/neutron/metadata_agent.ini
/etc/openstack-dashboard/local_settings.py
"

for f in $FILES; do
  # "sudo test" : les dossiers /etc/nova, /etc/glance... ne sont pas lisibles sans sudo
  if sudo test -f "$f"; then
    name="$(echo "$f" | sed 's|^/etc/||; s|/|_|g')"
    sudo grep -v '^\s*#' "$f" | grep -v '^\s*$' \
      | grep -v 'SECRET_KEY' \
      | sed "s|$PW|<PASSWORD>|g" > "$DEST/$name"
    echo "OK  $f -> $DEST/$name"
  else
    echo "--  $f (absent sur cette machine)"
  fi
done

echo
echo "Contrôle : lignes contenant encore le mot de passe (doit afficher 0) :"
grep -rcF -e "$PW" "$DEST" | grep -v ':0$' || echo 0
