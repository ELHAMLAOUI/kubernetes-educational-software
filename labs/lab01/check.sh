#!/usr/bin/env bash
# Vérification automatique du lab 01 — Mon premier Pod
source "$(dirname "$0")/../../lib/common.sh"
lab_begin "01" "Mon premier Pod" "lab01"

require_exists pod web "Créez un Pod nommé 'web' dans le namespace lab01 (metadata.namespace)."

check_eq 2 "Le conteneur utilise l'image nginx:1.25" \
  "Champ spec.containers[0].image" \
  "$(jp pod web '{.spec.containers[0].image}')" "nginx:1.25"

check_eq 2 "Le Pod porte le label app=web" \
  "Ajoutez metadata.labels.app: web" \
  "$(jp pod web '{.metadata.labels.app}')" "web"

check_eq 2 "Le conteneur expose le port 80" \
  "Champ spec.containers[0].ports[0].containerPort" \
  "$(jp pod web '{.spec.containers[0].ports[0].containerPort}')" "80"

check_cmd 3 "Le Pod est prêt (Ready) dans un délai de 60 s" \
  "Consultez 'kubectl -n lab01 describe pod web' (section Events)." \
  kubectl -n lab01 wait --for=condition=Ready pod/web --timeout=60s

lab_end
