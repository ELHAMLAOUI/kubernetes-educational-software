# Indices — Lab 03
1. `kubectl -n lab03 edit deploy/front` ou `kubectl -n lab03 patch deploy/front -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'`
2. `kubectl -n lab03 set image deploy/front nginx=nginx:1.27`
3. Retour arrière : `kubectl -n lab03 rollout undo deploy/front`
