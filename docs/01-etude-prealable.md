# Partie 1 - Étude préalable et préparation

## 1. OpenStack et son intérêt pour un Cloud privé
OpenStack est une plateforme open source qui transforme un ensemble de serveurs en cloud privé de type IaaS : machines virtuelles, réseaux virtuels et stockage à la demande, pilotés par une interface web (Horizon), une API REST ou la ligne de commande.

Intérêts : données conservées dans notre infrastructure, absence de licence et de dépendance à un fournisseur, libre-service avec quotas et multi-projets, extension de la capacité par ajout de nœuds compute.

## 2. et 3. Composants et rôles

| Service | Rôle |
|---|---|
| Keystone | Authentification, autorisation, catalogue des services |
| Nova | Cycle de vie des VM (nova-api, scheduler, conductor sur le contrôleur ; nova-compute sur chaque compute, via libvirt/QEMU) |
| Neutron | Réseaux virtuels, sous-réseaux, routeurs, groupes de sécurité, DHCP |
| Glance | Catalogue des images disque |
| Cinder | Volumes de stockage en mode bloc (non déployé dans ce TP) |
| Horizon | Interface web d'administration |
| Placement | Inventaire des ressources (CPU, RAM, disque) et allocations ; aide le scheduler de Nova à choisir un hôte |

Services de support : MariaDB (bases de données), RabbitMQ (messages entre services), Memcached (cache de jetons), Chrony (synchronisation d'horloge).

Flux de lancement d'une VM : client, Keystone (jeton), Nova API, scheduler (interroge Placement), nova-compute de l'hôte choisi, image récupérée chez Glance, port réseau demandé à Neutron, démarrage par libvirt/QEMU.

## 4. Caractéristiques des machines

| Machine | Processeur | RAM | Disque | Système | Virtualisation matérielle (`vmx`/`svm`) | `kvm-ok` |
|---|---|---|---|---|---|---|
| controller | à compléter | à compléter | à compléter | Ubuntu Server 24.04 | à compléter | à compléter |
| compute1 | à compléter | à compléter | à compléter | Ubuntu Server 24.04 | à compléter | à compléter |
| compute2 | à compléter | à compléter | à compléter | Ubuntu Server 24.04 | à compléter | à compléter |

Commandes utilisées : `lscpu`, `free -h`, `df -h /`, `lsb_release -a`, `egrep -c '(vmx|svm)' /proc/cpuinfo`, `kvm-ok`.

Captures à ajouter : `docs/images/jour1-01-materiel-controller.png`, `jour1-02-materiel-compute1.png`, `jour1-03-materiel-compute2.png`.

## 5. Choix de la méthode de déploiement
Installation manuelle selon l'Install Guide officiel.

- Elle permet un déploiement multi-nœuds (1 contrôleur + 2 compute), exactement l'architecture de référence.
- Elle montre chaque service un par un, ce qui répond à l'objectif pédagogique.
- DevStack est mono-nœud et fragile, Kolla-Ansible demande beaucoup de RAM, MicroStack masque le fonctionnement interne.
- Nos machines n'ont pas de virtualisation matérielle : hyperviseur **QEMU** (`virt_type = qemu`), image **CirrOS** légère.
- Le réseau de management est assuré par **ZeroTier** : IP fixes, trafic chiffré, pas besoin d'un réseau local commun.
