# Lab 01 — Mon premier Pod

**Durée indicative :** 20 min · **Namespace :** `lab01`
**Objectifs :** écrire un manifeste de Pod, l'appliquer, observer son cycle de vie.

## Contexte
Un Pod est la plus petite unité déployable de Kubernetes. Vous allez déployer un serveur web
nginx dans un Pod et vérifier qu'il fonctionne.

## Étapes

1. **Préparer l'environnement**
   ```bash
   ./labctl start 01
   ```
2. **Écrire le manifeste** `pod-web.yaml` avec les caractéristiques suivantes :
   | Champ | Valeur attendue |
   |---|---|
   | Nom du Pod | `web` |
   | Namespace | `lab01` |
   | Label | `app: web` |
   | Image | `nginx:1.25` |
   | Port du conteneur | `80` |
3. **Appliquer le manifeste**
   ```bash
   kubectl apply -f pod-web.yaml
   ```
4. **Observer** le Pod passer en `Running` :
   ```bash
   kubectl -n lab01 get pods -w
   kubectl -n lab01 describe pod web
   ```
5. **Vérifier votre travail**
   ```bash
   ./labctl check 01
   ```

## Pour aller plus loin
- `kubectl -n lab01 logs web`
- `kubectl -n lab01 port-forward pod/web 8080:80` puis ouvrez http://localhost:8080

## Questions de réflexion
1. Que se passe-t-il si vous supprimez le Pod ? Est-il recréé ? Pourquoi ?
2. Quelle est la différence entre `kubectl create` et `kubectl apply` ?
