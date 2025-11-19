#!/usr/bin/env bash
# Préparation du lab 01 : namespace vide
set -e
kubectl create namespace lab01 --dry-run=client -o yaml | kubectl apply -f -
echo "Namespace lab01 prêt. Lisez labs/lab01/README.md"
