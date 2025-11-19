#!/usr/bin/env bash
# Vérification automatique du lab 04 — Service
source "$(dirname "$0")/../../lib/common.sh"
lab_begin "04" "Exposer une application avec un Service" "lab04"

require_exists service api-svc "Créez un Service nommé 'api-svc' dans le namespace lab04."

check_eq 2 "Le Service est de type ClusterIP" \
  "spec.type (valeur par défaut si omis)" \
  "$(jp service api-svc '{.spec.type}')" "ClusterIP"

check_eq 2 "Le sélecteur cible app=api" \
  "spec.selector.app doit correspondre au label des Pods" \
  "$(jp service api-svc '{.spec.selector.app}')" "api"

check_eq 1 "Le Service écoute sur le port 80" \
  "spec.ports[0].port" \
  "$(jp service api-svc '{.spec.ports[0].port}')" "80"

check_eq 1 "Le trafic est envoyé au port 80 des Pods" \
  "spec.ports[0].targetPort" \
  "$(jp service api-svc '{.spec.ports[0].targetPort}')" "80"

eps=$(kubectl -n lab04 get endpoints api-svc -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
check_eq 3 "Le Service a 3 Endpoints (un par Pod)" \
  "Si 0 Endpoint : le sélecteur ne correspond à aucun Pod." \
  "$(count_words "$eps")" "3"

kubectl -n lab04 delete pod lab-check --ignore-not-found >/dev/null 2>&1
out=$(kubectl -n lab04 run lab-check --rm -i --restart=Never --quiet --image=busybox:1.36 \
      --command -- wget -qO- -T 5 http://api-svc 2>/dev/null)
check_contains 3 "Test fonctionnel : http://api-svc répond depuis un Pod du cluster" \
  "Vérifiez port/targetPort et les Endpoints." \
  "$out" "Welcome to nginx"

lab_end
