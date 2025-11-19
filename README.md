# Labs Kubernetes guidés avec vérification automatique

Didacticiel pour apprendre Kubernetes par la pratique : 7 labs progressifs, chacun avec un énoncé pas à pas, des indices et un **script de vérification automatique** qui inspecte le cluster de l'étudiant, explique chaque erreur et attribue une note sur 20.

Public : élèves ingénieurs (2e/3e année), modules Cloud / DevOps / Architectures distribuées.
Prérequis : bases de Linux et de Docker.

## Parcours

| Lab | Thème | Notions | Durée |
|---|---|---|---|
| 01 | Mon premier Pod | manifeste YAML, cycle de vie, labels | 20 min |
| 02 | Deployment et auto-réparation | ReplicaSet, sélecteurs, état désiré | 25 min |
| 03 | Mise à jour progressive | rolling update, maxSurge/maxUnavailable, révisions, rollback | 30 min |
| 04 | Exposer avec un Service | ClusterIP, Endpoints, DNS interne | 25 min |
| 05 | ConfigMap et Secret | configuration externalisée, envFrom, volumes | 30 min |
| 06 | Sondes et ressources | readiness/liveness, requests/limits, QoS | 30 min |
| 07 | Diagnostic d'une application en panne | démarche get/describe/events, 3 pannes à réparer | 40 min |

## Installation (poste étudiant)

1. Installer **Docker**, **kubectl** et **kind** (ou minikube / k3d).
2. Créer le cluster :
   ```bash
   kind create cluster --name labs
   ```
3. Cloner ce dépôt, puis :
   ```bash
   ./labctl list
   ./labctl start 01
   ```

## Utilisation

```bash
./labctl start 01     # prépare l'environnement du lab
./labctl hint 01      # indices
./labctl check 01     # vérification automatique + note /20
./labctl reset 01     # repartir de zéro
./labctl report       # bilan de tous les labs -> results/rapport.csv
```

Exemple de sortie de `./labctl check 01` :

```
Lab 01 — Mon premier Pod  (namespace : lab01)
--------------------------------------------------------------
  ✔ La ressource pod/web existe dans le namespace lab01 (+1)
  ✘ Le conteneur utilise l'image nginx:1.25 (0/2)
      obtenu : 'nginx:latest' — attendu : 'nginx:1.25'
      Indice : Champ spec.containers[0].image
  ✔ Le Pod porte le label app=web (+2)
  ...
Lab 01 : 8/10 points — note 16.0/20 (4/5 vérifications)
```

## Fonctionnement de la vérification automatique

Chaque `labs/labNN/check.sh` interroge l'API du cluster (`kubectl ... -o jsonpath`) et compare l'état réel à l'état attendu. Selon les labs, il fait aussi des **tests fonctionnels** : requête HTTP depuis un Pod temporaire, lecture des variables d'environnement, suppression d'un Pod pour tester l'auto-réparation. Chaque vérification ratée affiche la valeur obtenue, la valeur attendue et un indice. Les résultats sont enregistrés en JSON dans `results/`.

## Correction automatique des rendus (enseignant)

- `.github/workflows/autograding.yml` : à chaque push, un cluster kind éphémère est créé, les rendus de `rendu/labNN/` sont appliqués, puis tous les labs sont vérifiés. Le rapport est publié en artefact. Le workflow est compatible avec GitHub Classroom.
- `.github/workflows/selftest.yml` : vérifie que les solutions de référence obtiennent 20/20, ce qui garantit la cohérence du didacticiel.

## Tests du didacticiel

- `tests/run-tests.sh` exécute tous les scripts de vérification contre un **kubectl simulé**, sans cluster. Trois scénarios sont testés : solutions de référence (20/20 attendu à chaque lab), état de départ (0 point attendu, aucun point gratuit) et erreurs d'étudiant typiques (erreurs détectées attendues). Ce test est lancé à chaque push (`.github/workflows/tests.yml`).
- `.github/workflows/selftest.yml` (lancement manuel) refait le même contrôle sur un **vrai cluster** kind.

## Structure

```
labctl                 pilote (start / check / hint / reset / report)
lib/common.sh          primitives de vérification, notation, export JSON
labs/labNN/            README.md (énoncé), setup.sh, check.sh, hints.md
solutions/             solutions de référence (version enseignant uniquement)
tests/                 kubectl simulé et tests hors cluster
rendu/                 dépôt des rendus étudiants
.github/workflows/     correction automatique et auto-test
```

## Ajouter un lab

Copier un dossier `labs/labNN`, écrire l'énoncé, puis le `check.sh` avec les primitives `require_exists`, `check_eq`, `check_ge`, `check_contains` et `check_cmd` de `lib/common.sh`.
