# Indices — Lab 02
1. Brouillon : `kubectl create deployment api --image=nginx:1.25 --replicas=3 --port=80 -n lab02 --dry-run=client -o yaml`
2. Les labels de `spec.template.metadata.labels` doivent contenir ceux de `spec.selector.matchLabels`.
