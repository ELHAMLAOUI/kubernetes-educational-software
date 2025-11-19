#!/usr/bin/env bash
set -e
kubectl create namespace lab04 --dry-run=client -o yaml | kubectl apply -f -
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: lab04
spec:
  replicas: 3
  selector:
    matchLabels: { app: api }
  template:
    metadata:
      labels: { app: api }
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports: [ { containerPort: 80 } ]
YAML
kubectl -n lab04 rollout status deploy/api --timeout=120s
echo "Deployment api prêt. Lisez labs/lab04/README.md"
