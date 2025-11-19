# Indices — Lab 01
1. Squelette d'un Pod : `apiVersion: v1`, `kind: Pod`, `metadata`, `spec.containers[]`.
2. Générez un brouillon : `kubectl run web --image=nginx:1.25 --port=80 --labels=app=web -n lab01 --dry-run=client -o yaml`
3. Si le Pod reste en `ErrImagePull`, vérifiez l'orthographe de l'image.
