#!/usr/bin/env bash
# Applique toutes les solutions de référence (auto-test du didacticiel / démonstration)
set -e
D="$(cd "$(dirname "$0")" && pwd)"
for n in 01 02 03 04 05 06 07; do
  bash "$D/../labs/lab$n/setup.sh"
  if [ -f "$D/lab$n.yaml" ]; then kubectl apply -f "$D/lab$n.yaml"; else bash "$D/lab$n.sh"; fi
done
