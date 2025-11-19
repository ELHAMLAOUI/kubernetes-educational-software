#!/usr/bin/env bash
set -e
kubectl -n lab03 patch deploy/front -p '{"spec":{"strategy":{"type":"RollingUpdate","rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
kubectl -n lab03 set image deploy/front nginx=nginx:1.27
kubectl -n lab03 annotate deploy/front kubernetes.io/change-cause='passage en 1.27' --overwrite
kubectl -n lab03 rollout status deploy/front --timeout=180s
