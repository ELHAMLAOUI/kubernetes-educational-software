#!/usr/bin/env bash
# Vérification automatique du lab 07 — Diagnostic
source "$(dirname "$0")/../../lib/common.sh"
lab_begin "07" "Diagnostic : réparer une application en panne" "lab07"

require_present deployment shop "Relancez ./labctl start 07 (ne supprimez pas les objets, corrigez-les)."
require_present service shop-svc "Relancez ./labctl start 07."

check_cmd 3 "Erreur 1 corrigée : les Pods démarrent (image valide, rollout terminé)" \
  "Regardez les Events d'un Pod : ErrImagePull / ImagePullBackOff ?" \
  kubectl -n lab07 rollout status deploy/shop --timeout=120s

check_eq 1 "2 Pods prêts" "kubectl -n lab07 get deploy shop" \
  "$(jp deployment shop '{.status.readyReplicas}')" "2"

check_eq 3 "Erreur 2 corrigée : le sélecteur du Service correspond aux Pods" \
  "Comparez 'get pods --show-labels' et le selector du Service." \
  "$(jp service shop-svc '{.spec.selector.app}')" "shop"

check_eq 3 "Erreur 3 corrigée : targetPort = port du conteneur (80)" \
  "Sur quel port nginx écoute-t-il dans le conteneur ?" \
  "$(jp service shop-svc '{.spec.ports[0].targetPort}')" "80"

eps=$(kubectl -n lab07 get endpoints shop-svc -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
check_eq 2 "Le Service a 2 Endpoints" "kubectl -n lab07 get endpoints shop-svc" \
  "$(count_words "$eps")" "2"

kubectl -n lab07 delete pod lab-check --ignore-not-found >/dev/null 2>&1
out=$(kubectl -n lab07 run lab-check --rm -i --restart=Never --quiet --image=busybox:1.36 \
      --command -- wget -qO- -T 5 http://shop-svc 2>/dev/null)
check_contains 3 "Test fonctionnel : http://shop-svc répond" \
  "Les trois erreurs doivent être corrigées." "$out" "Welcome to nginx"

DIAG="$(dirname "$0")/diagnostic.txt"
diag=$(cat "$DIAG" 2>/dev/null | tr '[:upper:]' '[:lower:]')
check_nonempty 1 "Fichier diagnostic.txt présent" \
  "Créez labs/lab07/diagnostic.txt" "$diag"
check_contains 1 "Le diagnostic mentionne le problème d'image" \
  "Décrivez l'erreur liée à l'image." "$diag" "image"
check_contains 1 "Le diagnostic mentionne le problème de sélecteur / label" \
  "Décrivez l'erreur liée au sélecteur." "$diag" "s[ée]lect\|selector\|label"
check_contains 1 "Le diagnostic mentionne le problème de port" \
  "Décrivez l'erreur liée au port." "$diag" "targetport\|port"

lab_end
