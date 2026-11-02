# Partie 2 - Journal d'installation (Jours 1 à 4)

Conventions : `<PASSWORD>` désigne le mot de passe de laboratoire (non publié). Les fichiers de configuration complets et nettoyés sont dans `configs/`. Réseau ZeroTier : controller 10.75.2.11, compute1 10.75.2.31, compute2 10.75.2.32.

## Jour 1 - Préparation des 3 machines

**Noms d'hôte** (un par machine) :
```
sudo hostnamectl set-hostname controller     # compute1 / compute2 sur les autres
```

**ZeroTier** (réseau privé, chiffré) : création du réseau sur my.zerotier.com, puis sur chaque machine :
```
curl -s https://install.zerotier.com | sudo bash
sudo zerotier-cli join <NETWORK_ID>
```
Chaque membre est autorisé sur le site et reçoit une IP fixe. Vérification : `sudo zerotier-cli listnetworks`, `ip -br a`, `ping` entre les machines.

**Résolution de noms** (`/etc/hosts`) : controller, compute1 et compute2 pointent vers leurs IP ZeroTier ; la ligne `127.0.1.1` est supprimée.

**Horloge** (Chrony) : le contrôleur sert l'heure (`allow 10.75.2.0/24`), les compute utilisent `server controller iburst`. Vérification : `chronyc sources`.

**Module réseau** `br_netfilter` et paramètres `bridge-nf-call-iptables` : nécessaires pour que les groupes de sécurité s'appliquent aux ponts réseau.

Captures à ajouter : `jour1-04-zerotier-listnetworks.png`, `jour1-05-ping-noeuds.png`, `jour1-06-chrony-sources.png`.

## Jour 2 - Contrôleur : services de base, Keystone, Glance, Placement

**Services de base** :
```
sudo apt install -y mariadb-server python3-pymysql rabbitmq-server memcached \
  python3-memcache python3-openstackclient
```
- MariaDB : `bind-address = 10.75.2.11` (écoute uniquement sur ZeroTier), une base par service (keystone, glance, placement, neutron, nova_api, nova, nova_cell0), un utilisateur par service.
- RabbitMQ : utilisateur `openstack` avec les droits de configuration, écriture et lecture.
- Memcached : écoute sur `10.75.2.11`. Un fichier systemd attend que l'IP ZeroTier existe avant le démarrage (voir `05-problemes-solutions.md`, problème 2).

**Keystone** : `keystone-manage db_sync`, `fernet_setup`, `credential_setup`, `bootstrap` ; création du projet `service` ; fichier `admin-openrc` (non publié). Vérification : `openstack token issue`.

**Glance** : création de l'utilisateur, du rôle, du service `image` et des 3 endpoints ; `glance-manage db_sync` ; import de CirrOS 0.6.2 :
```
openstack image create "cirros" --file cirros-0.6.2-x86_64-disk.img \
  --disk-format qcow2 --container-format bare --public
```

**Placement** : même schéma ; `placement-manage db sync` ; vérification avec `sudo placement-status upgrade check`.

Vérifications : `openstack service list`, `openstack endpoint list`, `openstack image list`.

Captures à ajouter : `jour2-01-token-issue.png` (sans afficher le jeton complet), `jour2-02-service-list.png`, `jour2-03-endpoint-list.png`, `jour2-04-image-list.png`, `jour2-05-placement-check.png`.

## Jour 3 - Nova (calcul) avec QEMU

**Contrôleur** : utilisateur, service `compute` et endpoints ; paquets `nova-api nova-conductor nova-novncproxy nova-scheduler` ; configuration de `nova.conf` (bases, RabbitMQ, Keystone, VNC, Glance, Placement) ; puis :
```
nova-manage api_db sync
nova-manage cell_v2 map_cell0
nova-manage cell_v2 create_cell --name=cell1 --verbose
nova-manage db sync
nova-manage cell_v2 list_cells
```
(exécutées via `sudo su -s /bin/sh -c "..." nova`). L'avertissement « RLock(s) were not greened » est sans conséquence.

**compute1 et compute2** : paquet `nova-compute`, `nova.conf` avec `my_ip` propre à chaque machine, et dans `/etc/nova/nova-compute.conf` :
```
[libvirt]
virt_type = qemu
```
**Contrôleur** : `nova-manage cell_v2 discover_hosts --verbose`, puis `openstack compute service list` et `openstack hypervisor list` ; le type d'hyperviseur doit être `QEMU`.

Captures à ajouter : `jour3-01-list-cells.png`, `jour3-02-compute-service-list.png`, `jour3-03-hypervisor-qemu.png`.

## Jour 4 - Neutron (réseau) et Horizon

**Contrôleur** : utilisateur, service `network` et endpoints ; paquets `neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent` ; fichiers `neutron.conf`, `ml2_conf.ini`, `linuxbridge_agent.ini`, `l3_agent.ini`, `dhcp_agent.ini`, `metadata_agent.ini` ; section `[neutron]` dans `nova.conf` ; puis :
```
neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head
```
Choix techniques : réseaux de projet en **VXLAN** (le trafic des VM est encapsulé et circule dans le tunnel ZeroTier), `local_ip` = IP ZeroTier de chaque machine, `l2_population` activé, pas de réseau « provider » (pas de seconde carte réseau).

**compute1 et compute2** : `neutron-linuxbridge-agent`, `neutron.conf` minimal (RabbitMQ et Keystone, sans base de données), `linuxbridge_agent.ini` avec leur propre `local_ip`, section `[neutron]` dans `nova.conf`.

Vérification : `openstack network agent list` doit montrer 3 agents Linux bridge, DHCP, L3 et Metadata, tous `UP`.

**Horizon** : paquet `openstack-dashboard`, puis dans `/etc/openstack-dashboard/local_settings.py` : `OPENSTACK_HOST`, `ALLOWED_HOSTS`, `SESSION_ENGINE`, `CACHES` (Memcached), `OPENSTACK_KEYSTONE_URL`, `OPENSTACK_API_VERSIONS`, `TIME_ZONE = "Africa/Casablanca"`. Accès : `http://10.75.2.11/horizon` (domaine `Default`, utilisateur `admin`).

Captures à ajouter : `jour4-01-network-agent-list.png`, `jour4-02-horizon-login.png`, `jour4-03-horizon-hypervisors.png`.

## Jour 5
Voir `03-ressources-cloud.md` et `04-tests-validation.md`.
