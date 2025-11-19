# Indices — Lab 04
1. Brouillon : `kubectl -n lab04 expose deployment api --name=api-svc --port=80 --target-port=80 --dry-run=client -o yaml`
2. `kubectl -n lab04 get pods --show-labels` pour comparer labels et sélecteur.
