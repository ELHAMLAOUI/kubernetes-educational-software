#!/usr/bin/env bash
# Vérification automatique du lab 02 — Deployment et auto-réparation
source "$(dirname "$0")/../../lib/common.sh"
lab_begin "02" "Deployment et auto-réparation" "lab02"

require_exists deployment api "Créez un Deployment nommé 'api' dans le namespace lab02."

check_eq 2 "Le Deployment demande 3 réplicas" \
  "Champ spec.replicas" \
  "$(jp deployment api '{.spec.replicas}')" "3"

check_eq 2 "Le sélecteur cible app=api" \
  "Champ spec.selector.matchLabels.app" \
  "$(jp deployment api '{.spec.selector.matchLabels.app}')" "api"

check_eq 1 "Le modèle de Pod porte le label app=api" \
  "Champ spec.template.metadata.labels.app" \
  "$(jp deployment api '{.spec.template.metadata.labels.app}')" "api"

check_eq 2 "Les conteneurs utilisent l'image nginx:1.25" \
  "Champ spec.template.spec.containers[0].image" \
  "$(jp deployment api '{.spec.template.spec.containers[0].image}')" "nginx:1.25"

check_cmd 2 "Le déploiement est terminé (rollout complet en moins de 90 s)" \
  "kubectl -n lab02 rollout status deployment/api" \
  kubectl -n lab02 rollout status deployment/api --timeout=90s

check_eq 2 "3 Pods sont prêts" \
  "Comparez READY dans 'kubectl -n lab02 get deploy api'." \
  "$(jp deployment api '{.status.readyReplicas}')" "3"

# Auto-réparation : on supprime un Pod et on vérifie qu'il est remplacé.
victim=$(kubectl -n lab02 get pods -l app=api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$victim" ]; then
  kubectl -n lab02 delete pod "$victim" --wait=false >/dev/null 2>&1
  sleep 3
fi
WANT=$(jp deployment api '{.spec.replicas}')
export WANT
check_cmd 3 "Auto-réparation : un Pod supprimé est remplacé" \
  "Le Deployment doit gérer les Pods : ne créez pas de Pods à la main." \
  bash -c '[ "${WANT:-0}" -gt 0 ] || exit 1; for i in $(seq 1 30); do r=$(kubectl -n lab02 get deploy api -o jsonpath="{.status.readyReplicas}"); n=$(kubectl -n lab02 get pods -l app=api --field-selector=status.phase=Running --no-headers 2>/dev/null | grep -vc Terminating); [ "$r" = "$WANT" ] && [ "$n" -ge "$WANT" ] && exit 0; sleep 2; done; exit 1'

lab_end
