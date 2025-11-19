#!/usr/bin/env bash
set -e
kubectl create namespace lab02 --dry-run=client -o yaml | kubectl apply -f -
echo "Namespace lab02 prêt. Lisez labs/lab02/README.md"
