# Lab 03 — Mise à jour progressive (rolling update)

**Durée indicative :** 30 min · **Namespace :** `lab03`
**Objectifs :** mettre à jour une application sans interruption de service, tracer les versions, savoir revenir en arrière.

## Situation de départ
`./labctl start 03` crée le Deployment `front` (4 réplicas, image `nginx:1.25`).

## Étapes

1. `./labctl start 03` puis observez : `kubectl -n lab03 get deploy,rs,pods`
2. **Stratégie zéro interruption** : modifiez la stratégie de `front` pour que
   - `maxUnavailable` = `0` (aucun Pod indisponible pendant la mise à jour)
   - `maxSurge` = `1` (un Pod supplémentaire au maximum)
3. **Mise à jour** : passez l'image du conteneur `nginx` en `nginx:1.27`.
4. **Traçabilité** : ajoutez au Deployment l'annotation
   `kubernetes.io/change-cause` avec la valeur `passage en 1.27`.
5. Suivez la mise à jour : `kubectl -n lab03 rollout status deploy/front`
6. Consultez l'historique : `kubectl -n lab03 rollout history deploy/front`
7. `./labctl check 03`

## Questions de réflexion
1. Pourquoi `maxUnavailable: 0` garantit-il la continuité de service ? Quel en est le coût ?
2. Écrivez la commande qui reviendrait à la révision précédente (ne l'exécutez qu'après le check).
3. Combien de ReplicaSets existent après la mise à jour ? Pourquoi l'ancien est-il conservé ?
