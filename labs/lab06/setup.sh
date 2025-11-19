#!/usr/bin/env bash
set -e
kubectl create namespace lab06 --dry-run=client -o yaml | kubectl apply -f -
echo "Namespace lab06 prêt. Lisez labs/lab06/README.md"
