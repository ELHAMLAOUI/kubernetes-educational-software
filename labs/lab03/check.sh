#!/usr/bin/env bash
# Vérification automatique du lab 03 — Rolling update
source "$(dirname "$0")/../../lib/common.sh"
lab_begin "03" "Mise à jour progressive" "lab03"

require_present deployment front "Relancez ./labctl start 03 pour recréer le Deployment de départ."

check_eq 2 "Stratégie : maxUnavailable = 0" \
  "spec.strategy.rollingUpdate.maxUnavailable" \
  "$(jp deployment front '{.spec.strategy.rollingUpdate.maxUnavailable}')" "0"

check_eq 2 "Stratégie : maxSurge = 1" \
  "spec.strategy.rollingUpdate.maxSurge" \
  "$(jp deployment front '{.spec.strategy.rollingUpdate.maxSurge}')" "1"

check_eq 3 "L'image est passée en nginx:1.27" \
  "kubectl -n lab03 set image deploy/front nginx=nginx:1.27" \
  "$(jp deployment front '{.spec.template.spec.containers[0].image}')" "nginx:1.27"

check_eq 2 "Annotation change-cause renseignée" \
  "kubectl -n lab03 annotate deploy/front kubernetes.io/change-cause='passage en 1.27' --overwrite" \
  "$(jp deployment front '{.metadata.annotations.kubernetes\.io/change-cause}')" "passage en 1.27"

img=$(jp deployment front '{.spec.template.spec.containers[0].image}')
if [ "$img" = "nginx:1.27" ] && kubectl -n lab03 rollout status deploy/front --timeout=120s >/dev/null 2>&1; then
  done_rollout="terminée"
else
  done_rollout="non terminée"
fi
check_eq 2 "La mise à jour vers nginx:1.27 est terminée" \
  "kubectl -n lab03 rollout status deploy/front" \
  "$done_rollout" "terminée"

check_eq 2 "Les 4 réplicas tournent nginx:1.27" \
  "Attendez la fin du rollout." \
  "$img $(jp deployment front '{.status.updatedReplicas}')/$(jp deployment front '{.status.readyReplicas}')" "nginx:1.27 4/4"

rev=$(jp deployment front '{.metadata.annotations.deployment\.kubernetes\.io/revision}')
check_ge 2 "Une nouvelle révision a été créée (révision ≥ 2)" \
  "Une mise à jour du template de Pod crée une nouvelle révision." \
  "$rev" 2

lab_end
