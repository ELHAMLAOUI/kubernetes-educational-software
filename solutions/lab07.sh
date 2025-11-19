#!/usr/bin/env bash
set -e
kubectl -n lab07 set image deploy/shop web=nginx:1.25
kubectl -n lab07 patch svc/shop-svc --type=json -p '[{"op":"replace","path":"/spec/selector/app","value":"shop"},{"op":"replace","path":"/spec/ports/0/targetPort","value":80}]'
kubectl -n lab07 rollout status deploy/shop --timeout=180s
cat > "$(dirname "$0")/../labs/lab07/diagnostic.txt" <<'TXT'
Erreur 1 - Image : Pods en ImagePullBackOff (kubectl describe pod). Tag nginx:1.255 inexistant -> nginx:1.25.
Erreur 2 - Sélecteur : 0 endpoint (kubectl get endpoints shop-svc). selector app=shopp -> app=shop (label des Pods).
Erreur 3 - Port : targetPort 8080 alors que nginx écoute sur 80 (kubectl describe svc). targetPort -> 80.
TXT
