# Lab 02 — Deployment et auto-réparation

**Durée indicative :** 25 min · **Namespace :** `lab02`
**Objectifs :** passer du Pod au Deployment, comprendre le rôle du ReplicaSet et l'auto-réparation.

## Étapes

1. `./labctl start 02`
2. Écrivez `deploy-api.yaml` :
   | Champ | Valeur attendue |
   |---|---|
   | Nom du Deployment | `api` |
   | Namespace | `lab02` |
   | Réplicas | `3` |
   | Sélecteur / label des Pods | `app: api` |
   | Image | `nginx:1.25` |
   | Port du conteneur | `80` |
3. `kubectl apply -f deploy-api.yaml`
4. **Expérience d'auto-réparation** : supprimez un Pod et observez.
   ```bash
   kubectl -n lab02 get pods
   kubectl -n lab02 delete pod <nom-d-un-pod>
   kubectl -n lab02 get pods -w
   ```
5. `./labctl check 02`

## Questions de réflexion
1. Quel objet recrée le Pod supprimé ? Montrez-le avec `kubectl -n lab02 get rs`.
2. Que se passe-t-il si le label des Pods ne correspond pas au sélecteur ?
