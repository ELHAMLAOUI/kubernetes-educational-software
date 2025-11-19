#!/usr/bin/env bash
# Vérification automatique du lab 05 — ConfigMap et Secret
source "$(dirname "$0")/../../lib/common.sh"
lab_begin "05" "ConfigMap et Secret" "lab05"

check_eq 1 "ConfigMap app-config : APP_MODE=production" \
  "kubectl -n lab05 create configmap app-config --from-literal=APP_MODE=production ..." \
  "$(jp configmap app-config '{.data.APP_MODE}')" "production"

check_eq 1 "ConfigMap app-config : APP_COLOR=blue" \
  "Ajoutez la clé APP_COLOR à la ConfigMap." \
  "$(jp configmap app-config '{.data.APP_COLOR}')" "blue"

check_eq 1 "Le Secret app-secret est de type Opaque" \
  "kubectl -n lab05 create secret generic app-secret ..." \
  "$(jp secret app-secret '{.type}')" "Opaque"

pwd_dec=$(jp secret app-secret '{.data.DB_PASSWORD}' | base64 -d 2>/dev/null)
check_eq 2 "Le Secret contient DB_PASSWORD (valeur correcte)" \
  "Dans un manifeste, .data attend du base64 ; utilisez .stringData pour du texte clair." \
  "$pwd_dec" "S3cret-2026"

if exists configmap app-config; then cm_pwd=$(jp configmap app-config '{.data.DB_PASSWORD}'); else cm_pwd="<ConfigMap absente>"; fi
check_eq 1 "Le mot de passe n'est PAS stocké dans la ConfigMap" \
  "Une donnée sensible va dans un Secret, jamais dans une ConfigMap." \
  "$cm_pwd" ""

require_exists pod app "Créez le Pod 'app' (busybox:1.36, sleep 3600)."

check_cmd 2 "Le Pod app est prêt" \
  "kubectl -n lab05 describe pod app" \
  kubectl -n lab05 wait --for=condition=Ready pod/app --timeout=60s

envs=$(kubectl -n lab05 exec app -- env 2>/dev/null)
cm_ref=$(jp pod app '{.spec.containers[0].envFrom[*].configMapRef.name}')
sec_ref=$(jp pod app '{.spec.containers[0].envFrom[*].secretRef.name}')
check_contains 3 "Variable APP_MODE injectée depuis la ConfigMap" \
  "spec.containers[0].envFrom[].configMapRef.name: app-config" \
  "$cm_ref|$(printf '%s' "$envs" | grep -x 'APP_MODE=production')" "app-config|APP_MODE=production"

check_contains 3 "Variable DB_PASSWORD injectée depuis le Secret" \
  "spec.containers[0].envFrom[].secretRef.name: app-secret" \
  "$sec_ref|$(printf '%s' "$envs" | grep -x 'DB_PASSWORD=S3cret-2026')" "app-secret|DB_PASSWORD=S3cret-2026"

check_eq 3 "La ConfigMap est montée en volume dans /etc/app" \
  "volumes[].configMap.name + volumeMounts[].mountPath: /etc/app" \
  "$(kubectl -n lab05 exec app -- cat /etc/app/APP_COLOR 2>/dev/null)" "blue"

lab_end
