# Problèmes rencontrés et solutions

Pour chaque incident : symptôme, diagnostic, cause, solution et enseignement.

## 1. `401 Unauthorized` lors de `openstack image create` (Glance)

**Symptôme** : `HttpException: 401 Client Error for url: http://controller:9292/v2/images ... 401 Unauthorized`, alors que `openstack token issue` fonctionnait.

**Diagnostic** : le journal `/var/log/glance/glance-api.log` montrait que Glance n'arrivait pas à joindre Keystone : `Failed to resolve '...'` avec un nom d'hôte mal orthographié (une lettre manquante). Les fichiers de configuration de Glance étaient corrects et le nom introuvable par `grep` dans `/etc`. Le résultat de `openstack endpoint list` a révélé l'origine : l'endpoint Keystone de type `internal` avait l'URL `http://conroller:5000/v3/`.

**Cause** : faute de frappe dans l'option `--bootstrap-internal-url` de `keystone-manage bootstrap`. L'URL est stockée **dans la base de données** (catalogue Keystone), pas dans un fichier ; Glance utilise par défaut l'endpoint `internal`.

**Solution** : correction de l'endpoint, puis retrait du contournement :
```
ID=$(openstack endpoint list --service identity --interface internal -f value -c ID)
openstack endpoint set --url http://controller:5000/v3/ $ID
```
Contournement utilisé pendant le diagnostic : alias du nom fautif dans `/etc/hosts` (retiré ensuite).

**Enseignement** : un 401 de Glance peut venir de la connexion de Glance vers Keystone ; lire le journal du service et vérifier le catalogue (`openstack endpoint list`).

<!-- À CONFIRMER avant publication : l'endpoint est corrigé et l'alias de /etc/hosts est retiré. -->

## 2. Memcached bloqué en `activating (start-pre)`

**Symptôme** : `Job for memcached.service failed because a timeout was exceeded` ; `systemctl status memcached` indiquait `activating (start-pre)` et `Cannot open netlink socket: Address family not supported by protocol`.

**Cause** : un fichier systemd (`wait-zt.conf`) faisait attendre l'IP ZeroTier avec la commande `ip -4 addr`. Dans l'environnement restreint du service, `ip` ne peut pas ouvrir de socket netlink : la boucle ne se terminait jamais.

**Solution** : lire l'adresse dans `/proc/net/fib_trie`, qui ne nécessite pas netlink, avec un délai de démarrage plus long :
```
[Unit]
After=zerotier-one.service
Wants=zerotier-one.service
[Service]
TimeoutStartSec=180
ExecStartPre=/bin/sh -c 'until grep -q "10.75.2.11" /proc/net/fib_trie; do sleep 2; done'
```
Puis `sudo systemctl daemon-reload` et `sudo systemctl restart memcached`.

**Enseignement** : une commande qui fonctionne dans un terminal peut échouer dans un service systemd sandboxé.

## 3. Fautes de saisie dans les commandes et les fichiers

| Symptôme | Cause | Correction |
|---|---|---|
| `invalid choice: 'qcrow2'` | lettre en trop dans `--disk-format` | `qcow2` |
| option inconnue `--controller-format` | confusion avec `--container-format` | `--container-format bare` |
| nano affiche un fichier vide, titre `kaystone.conf` | nom de fichier mal tapé : nouveau fichier créé | rouvrir `keystone.conf` ; utiliser la touche Tab pour compléter |
| `Missing value auth-url required for auth plugin password` | variables `OS_*` absentes du terminal | `source ~/admin-openrc` |

**Enseignement** : copier-coller les commandes, utiliser la complétion par Tab et lire le titre de nano avant d'éditer.

## 4. `neutron-db-manage upgrade head` : erreur SQLite

**Symptôme** : `NotImplementedError: No support for ALTER of constraints in SQLite dialect`.

**Cause** : la ligne `connection = mysql+pymysql://...` n'était pas lue dans la section `[database]` de `neutron.conf` ; Neutron utilisait SQLite par défaut.

**Solution** : placer la ligne `connection` sous le **vrai** titre `[database]` (repéré avec `sudo grep -n "^\[" /etc/neutron/neutron.conf`), puis relancer la migration (résultat `OK`).

## 5. `placement-status upgrade check` : `RequiredOptError ... [placement_database]`

**Cause** : `/etc/placement/placement.conf` n'est lisible que par `root` et le groupe `placement` ; l'outil lancé sans `sudo` ne lisait pas la configuration.

**Solution** : `sudo placement-status upgrade check`.

Remarque : la commande de synchronisation s'écrit `placement-manage db sync` (avec un espace), alors que Keystone et Glance utilisent `db_sync`.

## 6. Horizon : `500 Internal Server Error`

**Diagnostic** : `sudo tail /var/log/apache2/error.log` indiquait `SyntaxError: unterminated string literal` dans `local_settings.py`, à la ligne de `'BACKEND': ...`.

**Cause** : guillemet ouvrant manquant devant `django.core.cache.backends.memcached.PyMemcacheCache`.

**Solution** : corriger la ligne, vérifier avec `sudo python3 -m py_compile /etc/openstack-dashboard/local_settings.py`, puis `sudo systemctl restart apache2`.

## 7. Avertissement `3 RLock(s) were not greened` (nova-manage)

Message affiché à chaque exécution de `nova-manage` avec les paquets Ubuntu 24.04. Sans conséquence : les migrations (`Running upgrade ...`) se terminent correctement.

## 8. Modifier les bons paramètres dans les fichiers

- Les IP d'exemple (10.147.17.x) ont été remplacées par celles de notre réseau ZeroTier (10.75.2.x).
- Dans nano, `Ctrl+W` s'arrête sur les commentaires qui contiennent `[DEFAULT]` : la vraie section se trouve avec `sudo grep -n "^\[" fichier`, puis `Ctrl+_` et le numéro de ligne.
- Contrôle du fichier réel, sans commentaires : `sudo grep -v '^\s*#' fichier | grep -v '^\s*$'`.
