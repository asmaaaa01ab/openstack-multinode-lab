#!/bin/bash
# À lancer AVANT chaque commit, depuis la racine du dépôt :  ./scripts/check-secrets.sh
# Optionnel (recommandé) : export LAB_PASSWORD pour chercher aussi votre mot de passe exact.

PATTERNS='OS_PASSWORD|BEGIN (RSA|OPENSSH|EC) PRIVATE KEY|ghp_[A-Za-z0-9]|github_pat_|gAAAAA[A-Za-z0-9_-]{20,}'
FOUND=0

if grep -rnIE "$PATTERNS" --exclude-dir=.git --exclude=check-secrets.sh .; then FOUND=1; fi

if [ -n "${LAB_PASSWORD:-}" ]; then
  if grep -rnIF --exclude-dir=.git -e "$LAB_PASSWORD" .; then FOUND=1; fi
fi

echo "--- Fichiers à ne pas versionner présents dans le dépôt :"
find . -path ./.git -prune -o \( -name '*.img' -o -name '*.qcow2' -o -name '*-openrc' -o -name 'id_rsa*' -o -name 'id_ed25519*' -o -name '*.pem' -o -name '.env' \) -print

if [ "$FOUND" -eq 1 ]; then
  echo "ATTENTION : secrets détectés ci-dessus. Corrigez avant de faire le commit."
  exit 1
fi
echo "Aucun secret détecté dans les fichiers texte."
echo "Pensez à vérifier les captures d'écran (IP publiques, jetons, mots de passe visibles)."
