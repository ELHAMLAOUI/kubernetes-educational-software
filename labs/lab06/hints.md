# Indices — Lab 06
```yaml
readinessProbe:
  httpGet: { path: /, port: 80 }
livenessProbe:
  httpGet: { path: /, port: 80 }
  initialDelaySeconds: 5
resources:
  requests: { cpu: 100m, memory: 64Mi }
  limits:   { cpu: 250m, memory: 128Mi }
```
