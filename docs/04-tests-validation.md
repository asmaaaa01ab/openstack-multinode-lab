# Partie 4 - Tests et validation

Séance du Jour 5 (à compléter).

| # | Test | Résultat attendu | Résultat obtenu | Preuve |
|---|---|---|---|---|
| 1 | Instances démarrées | `ACTIVE`, `Running`, bon hôte | | `evidence/` + capture |
| 2 | Connectivité (ping via l'espace de noms du routeur) | réponses ICMP | | |
| 3 | Connexion SSH et ping vm1 vers vm2 | connexion par clé, ping via le routeur | | |
| 4 | Règles de sécurité : suppression puis recréation de la règle ICMP | ping échoue puis repasse | | |
| 5 | Arrêt, redémarrage, suppression d'une VM de test | `SHUTOFF`, `ACTIVE`, instance supprimée | | |
| 6 | Supervision : hyperviseurs, ressources, agents | type `QEMU`, usage CPU/RAM | | |
