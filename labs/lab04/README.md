# Lab 04 — Exposer une application avec un Service

**Durée indicative :** 25 min · **Namespace :** `lab04`
**Objectifs :** comprendre la découverte de service, le rôle des labels/sélecteurs et des Endpoints.

## Situation de départ
`./labctl start 04` crée le Deployment `api` (3 réplicas nginx, label `app: api`).

## Étapes

1. `./labctl start 04`
2. Écrivez `svc-api.yaml` :
   | Champ | Valeur attendue |
   |---|---|
   | Nom du Service | `api-svc` |
   | Type | `ClusterIP` |
   | Sélecteur | `app: api` |
   | Port du Service | `80` |
   | Port cible (targetPort) | `80` |
3. `kubectl apply -f svc-api.yaml`
4. Observez les Endpoints : `kubectl -n lab04 get endpoints api-svc`
5. Testez depuis un Pod temporaire :
   ```bash
   kubectl -n lab04 run test --rm -it --restart=Never --image=busybox:1.36 -- wget -qO- http://api-svc
   ```
6. `./labctl check 04`

## Questions de réflexion
1. Que deviennent les Endpoints si vous passez le Deployment à 1 réplica ?
2. Quel nom DNS complet permet d'atteindre ce Service depuis un autre namespace ?
