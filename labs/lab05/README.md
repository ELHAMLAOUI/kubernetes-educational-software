# Lab 05 — Configuration : ConfigMap et Secret

**Durée indicative :** 30 min · **Namespace :** `lab05`
**Objectifs :** externaliser la configuration (principe 12-factor), distinguer donnée de configuration et donnée sensible, injecter par variables d'environnement et par volume.

## Étapes

1. `./labctl start 05`
2. Créez la **ConfigMap** `app-config` contenant :
   - `APP_MODE` = `production`
   - `APP_COLOR` = `blue`
3. Créez le **Secret** `app-secret` (type `Opaque`) contenant :
   - `DB_PASSWORD` = `S3cret-2026`
4. Créez le **Pod** `app` :
   - image `busybox:1.36`, commande `sleep 3600`
   - toutes les clés de `app-config` **et** de `app-secret` injectées en variables d'environnement (`envFrom`)
   - la ConfigMap `app-config` montée en volume dans `/etc/app`
5. Vérifiez :
   ```bash
   kubectl -n lab05 exec app -- env | grep -E 'APP_|DB_'
   kubectl -n lab05 exec app -- cat /etc/app/APP_COLOR
   ```
6. `./labctl check 05`

## Questions de réflexion
1. Le Secret est-il chiffré ? Que montre `kubectl -n lab05 get secret app-secret -o yaml` ?
2. Si vous modifiez la ConfigMap, la variable d'environnement change-t-elle ? Et le fichier monté ?
