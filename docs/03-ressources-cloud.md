# Partie 3 - Création et administration des ressources Cloud

Séance du Jour 5 (à compléter).

| # | Étape | Commande | Fait | Capture |
|---|---|---|---|---|
| 1 | Importer l'image CirrOS 0.6.2 | `openstack image create ...` | oui (Jour 2) | à ajouter |
| 2 | Créer le flavor `m1.nano` (1 vCPU, 256 Mo, 1 Go) | `openstack flavor create ...` | | |
| 3 | Créer les réseaux privés `net-a` et `net-b` et leurs sous-réseaux | `openstack network create`, `subnet create` | | |
| 4 | Créer le routeur `router1` relié aux deux sous-réseaux | `openstack router create`, `router add subnet` | | |
| 5 | Créer la paire de clés SSH `mykey` | `openstack keypair create` | | |
| 6 | Créer le groupe de sécurité `lab-sg` (ICMP + SSH) | `openstack security group rule create` | | |
| 7 | Lancer `vm1` (compute1) et `vm2` (compute2) | `openstack server create` | | |
| 8 | Vérifier état, IP et ressources | `openstack server show` | | |

Plan d'adressage : net-a 172.16.1.0/24 (passerelle 172.16.1.1), net-b 172.16.2.0/24 (passerelle 172.16.2.1).

Accès externe : l'environnement ZeroTier n'offre pas de réseau « provider » ; le routeur relie donc deux réseaux privés.
