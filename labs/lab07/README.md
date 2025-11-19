# Lab 07 — Diagnostic : réparer une application en panne

**Durée indicative :** 40 min · **Namespace :** `lab07`
**Objectifs :** adopter une démarche de diagnostic (get → describe → logs → events), corriger des erreurs fréquentes.

## Situation de départ
`./labctl start 07` déploie l'application `shop` (Deployment + Service `shop-svc`).
Elle **ne fonctionne pas** : l'équipe signale que `http://shop-svc` ne répond pas.
Le comportement attendu : **2 Pods nginx prêts**, joignables via le Service `shop-svc` sur le port 80.

**Trois erreurs** ont été introduites. À vous de les trouver et de les corriger.

## Démarche conseillée
```bash
kubectl -n lab07 get all
kubectl -n lab07 describe deploy shop
kubectl -n lab07 describe pod <pod>
kubectl -n lab07 get events --sort-by=.lastTimestamp
kubectl -n lab07 get endpoints shop-svc
kubectl -n lab07 get pods --show-labels
```

## Livrables
1. L'application réparée (corrigez avec `kubectl edit`, `kubectl set` ou `kubectl apply`).
2. Un fichier `labs/lab07/diagnostic.txt` décrivant, pour chaque erreur :
   le **symptôme observé**, la **commande** qui l'a révélé et la **correction**.

Puis : `./labctl check 07`

## Règle du jeu
Ne supprimez pas le namespace et ne recréez pas tout de zéro : corrigez les objets existants.
