#!/usr/bin/env bash
# Préparation du lab 07 : application volontairement cassée (3 erreurs)
set -e
kubectl create namespace lab07 --dry-run=client -o yaml | kubectl apply -f -
cat <<'YAML' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
  namespace: lab07
spec:
  replicas: 2
  selector:
    matchLabels: { app: shop }
  template:
    metadata:
      labels: { app: shop }
    spec:
      containers:
        - name: web
          image: nginx:1.255
          ports: [ { containerPort: 80 } ]
---
apiVersion: v1
kind: Service
metadata:
  name: shop-svc
  namespace: lab07
spec:
  selector: { app: shopp }
  ports:
    - port: 80
      targetPort: 8080
YAML
echo "Application shop déployée... mais en panne. Lisez labs/lab07/README.md"
