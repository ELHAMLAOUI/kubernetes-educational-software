#!/usr/bin/env bash
# Vérification automatique du lab 06 — Sondes et ressources
source "$(dirname "$0")/../../lib/common.sh"
lab_begin "06" "Sondes de santé et ressources" "lab06"

require_exists deployment robust "Créez le Deployment 'robust' dans le namespace lab06."

C='{.spec.template.spec.containers[0]'

check_eq 1 "2 réplicas demandés" "spec.replicas" \
  "$(jp deployment robust '{.spec.replicas}')" "2"

check_eq 2 "readinessProbe httpGet sur / port 80" \
  "containers[0].readinessProbe.httpGet.{path,port}" \
  "$(jp deployment robust "$C.readinessProbe.httpGet.path}"):$(jp deployment robust "$C.readinessProbe.httpGet.port}")" "/:80"

check_eq 2 "livenessProbe httpGet sur / port 80" \
  "containers[0].livenessProbe.httpGet.{path,port}" \
  "$(jp deployment robust "$C.livenessProbe.httpGet.path}"):$(jp deployment robust "$C.livenessProbe.httpGet.port}")" "/:80"

check_eq 1 "livenessProbe : initialDelaySeconds = 5" \
  "containers[0].livenessProbe.initialDelaySeconds" \
  "$(jp deployment robust "$C.livenessProbe.initialDelaySeconds}")" "5"

check_eq 2 "requests : cpu 100m / memory 64Mi" \
  "containers[0].resources.requests" \
  "$(jp deployment robust "$C.resources.requests.cpu}")/$(jp deployment robust "$C.resources.requests.memory}")" "100m/64Mi"

check_eq 2 "limits : cpu 250m / memory 128Mi" \
  "containers[0].resources.limits" \
  "$(jp deployment robust "$C.resources.limits.cpu}")/$(jp deployment robust "$C.resources.limits.memory}")" "250m/128Mi"

check_cmd 2 "Le déploiement est terminé (sondes au vert)" \
  "Si les Pods ne deviennent pas Ready, vérifiez la readinessProbe." \
  kubectl -n lab06 rollout status deploy/robust --timeout=120s

qos=$(kubectl -n lab06 get pods -l app=robust -o jsonpath='{.items[0].status.qosClass}' 2>/dev/null)
check_eq 2 "Classe QoS des Pods : Burstable" \
  "requests < limits donne la classe Burstable." \
  "$qos" "Burstable"

lab_end
