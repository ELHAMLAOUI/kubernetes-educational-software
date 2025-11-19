# Lab 06 — Sondes de santé et ressources

**Durée indicative :** 30 min · **Namespace :** `lab06`
**Objectifs :** rendre une application observable par Kubernetes (readiness/liveness), maîtriser requests/limits et la classe QoS.

## Étapes

1. `./labctl start 06`
2. Écrivez le Deployment `robust` :
   | Champ | Valeur attendue |
   |---|---|
   | Réplicas | `2` |
   | Label / sélecteur | `app: robust` |
   | Image | `nginx:1.25` |
   | readinessProbe | `httpGet` sur `/`, port `80` |
   | livenessProbe | `httpGet` sur `/`, port `80`, `initialDelaySeconds: 5` |
   | requests | `cpu: 100m`, `memory: 64Mi` |
   | limits | `cpu: 250m`, `memory: 128Mi` |
3. `kubectl apply -f deploy-robust.yaml`
4. Observez la classe QoS :
   ```bash
   kubectl -n lab06 get pods -l app=robust -o custom-columns=NOM:.metadata.name,QOS:.status.qosClass
   ```
5. `./labctl check 06`

## Expérience (après le check)
Changez le chemin de la readinessProbe en `/inexistant` : que deviennent la colonne READY et les Endpoints d'un Service ?

## Questions de réflexion
1. Différence entre readiness et liveness : laquelle redémarre le conteneur ?
2. Que se passe-t-il si un conteneur dépasse sa limite mémoire ? Et sa limite CPU ?
