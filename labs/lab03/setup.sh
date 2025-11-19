#!/usr/bin/env bash
set -e
kubectl create namespace lab03 --dry-run=client -o yaml | kubectl apply -f -
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: front
  namespace: lab03
spec:
  replicas: 4
  selector:
    matchLabels: { app: front }
  template:
    metadata:
      labels: { app: front }
    spec:
      containers:
        - name: nginx
          image: nginx:1.25
          ports: [ { containerPort: 80 } ]
YAML
kubectl -n lab03 rollout status deploy/front --timeout=120s
echo "Deployment front (nginx:1.25, 4 réplicas) prêt. Lisez labs/lab03/README.md"
