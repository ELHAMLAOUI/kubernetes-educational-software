#!/usr/bin/env bash
set -e
kubectl create namespace lab05 --dry-run=client -o yaml | kubectl apply -f -
echo "Namespace lab05 prêt. Lisez labs/lab05/README.md"
