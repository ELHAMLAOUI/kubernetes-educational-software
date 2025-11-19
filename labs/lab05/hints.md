# Indices — Lab 05
1. `kubectl -n lab05 create configmap app-config --from-literal=APP_MODE=production --from-literal=APP_COLOR=blue`
2. `kubectl -n lab05 create secret generic app-secret --from-literal=DB_PASSWORD=S3cret-2026`
3. Dans le Pod : `envFrom: [ {configMapRef: {name: app-config}}, {secretRef: {name: app-secret}} ]`
4. Volume : `volumes: [{name: cfg, configMap: {name: app-config}}]` et `volumeMounts: [{name: cfg, mountPath: /etc/app}]`
