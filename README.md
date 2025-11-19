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

| Commande | Rôle |
|---|---|
| `./labctl list` | liste les labs |
| `./labctl start NN` | prépare l'environnement du lab (namespace, objets de départ) |
| `./labctl hint NN` | affiche les indices |
| `./labctl check NN` | vérifie le travail et donne une note sur 20 |
| `./labctl reset NN` | supprime le lab et le remet à l'état initial |
| `./labctl report` | bilan de tous les labs, exporté dans `results/rapport.csv` |
| `./labctl clean` | supprime les namespaces de tous les labs |

## Exemples d'usage

### 1. Séance type d'un étudiant (lab 01)

```bash
$ ./labctl list
  01  Lab 01 — Mon premier Pod
  02  Lab 02 — Deployment et auto-réparation
  03  Lab 03 — Mise à jour progressive (rolling update)
  04  Lab 04 — Exposer une application avec un Service
  05  Lab 05 — Configuration : ConfigMap et Secret
  06  Lab 06 — Sondes de santé et ressources
  07  Lab 07 — Diagnostic : réparer une application en panne

$ ./labctl start 01
namespace/lab01 created
Namespace lab01 prêt. Lisez labs/lab01/README.md
```

L'étudiant lit l'énoncé `labs/lab01/README.md`, puis écrit son manifeste `pod-web.yaml`. Il se trompe d'image et utilise `nginx:latest` au lieu de `nginx:1.25` :

```bash
$ kubectl apply -f pod-web.yaml
pod/web created

$ ./labctl check 01

Lab 01 — Mon premier Pod  (namespace : lab01)
--------------------------------------------------------------
  [OK] La ressource pod/web existe dans le namespace lab01 (+1)
  [KO] Le conteneur utilise l'image nginx:1.25 (0/2)
      obtenu : 'nginx:latest' — attendu : 'nginx:1.25'
      Indice : Champ spec.containers[0].image
  [OK] Le Pod porte le label app=web (+2)
  [OK] Le conteneur expose le port 80 (+2)
  [OK] Le Pod est prêt (Ready) dans un délai de 60 s (+3)
--------------------------------------------------------------
Lab 01 : 8/10 points — note 16.0/20 (4/5 vérifications)
Corrigez puis relancez : ./labctl check 01
```

Il corrige l'image, réapplique son manifeste et relance la vérification :

```bash
$ kubectl apply -f pod-web.yaml
pod/web configured
$ ./labctl check 01

Lab 01 — Mon premier Pod  (namespace : lab01)
--------------------------------------------------------------
  [OK] La ressource pod/web existe dans le namespace lab01 (+1)
  [OK] Le conteneur utilise l'image nginx:1.25 (+2)
  [OK] Le Pod porte le label app=web (+2)
  [OK] Le conteneur expose le port 80 (+2)
  [OK] Le Pod est prêt (Ready) dans un délai de 60 s (+3)
--------------------------------------------------------------
Lab 01 réussi : 10/10 points — note 20.0/20
```

### 2. Demander de l'aide

```bash
$ ./labctl hint 01
# Indices — Lab 01
1. Squelette d'un Pod : `apiVersion: v1`, `kind: Pod`, `metadata`, `spec.containers[]`.
2. Générez un brouillon : `kubectl run web --image=nginx:1.25 --port=80 --labels=app=web -n lab01 --dry-run=client -o yaml`
3. Si le Pod reste en `ErrImagePull`, vérifiez l'orthographe de l'image.
```

### 3. Une erreur qui se propage (lab 04)

Le sélecteur du Service est écrit `app: API` au lieu de `app: api`. La vérification montre l'erreur de départ, puis ses conséquences : aucun Endpoint, et le Service ne répond pas.

```bash
$ ./labctl check 04

Lab 04 — Exposer une application avec un Service  (namespace : lab04)
--------------------------------------------------------------
  [OK] La ressource service/api-svc existe dans le namespace lab04 (+1)
  [OK] Le Service est de type ClusterIP (+2)
  [KO] Le sélecteur cible app=api (0/2)
      obtenu : 'API' — attendu : 'api'
      Indice : spec.selector.app doit correspondre au label des Pods
  [OK] Le Service écoute sur le port 80 (+1)
  [OK] Le trafic est envoyé au port 80 des Pods (+1)
  [KO] Le Service a 3 Endpoints (un par Pod) (0/3)
      obtenu : '0' — attendu : '3'
      Indice : Si 0 Endpoint : le sélecteur ne correspond à aucun Pod.
  [KO] Test fonctionnel : http://api-svc répond depuis un Pod du cluster (0/3)
      motif 'Welcome to nginx' non trouvé
      Indice : Vérifiez port/targetPort et les Endpoints.
--------------------------------------------------------------
Lab 04 : 5/13 points — note 7.7/20 (4/7 vérifications)
Corrigez puis relancez : ./labctl check 04
```

### 4. Lab de diagnostic (lab 07)

`./labctl start 07` déploie une application volontairement cassée, qui contient trois erreurs. L'étudiant mène l'enquête :

```bash
$ ./labctl start 07
$ kubectl -n lab07 get pods
NAME                    READY   STATUS             RESTARTS   AGE
shop-7d9c8b6f4d-2xkqp   0/1     ImagePullBackOff   0          40s
shop-7d9c8b6f4d-9mzrt   0/1     ImagePullBackOff   0          40s
$ kubectl -n lab07 get endpoints shop-svc
NAME       ENDPOINTS   AGE
shop-svc   <none>      40s
```

Il corrige les objets, puis décrit sa démarche dans `labs/lab07/diagnostic.txt` :

```text
Erreur 1 - Image : Pods en ImagePullBackOff (kubectl describe pod). Tag nginx:1.255 inexistant -> nginx:1.25.
Erreur 2 - Sélecteur : 0 endpoint (kubectl get endpoints shop-svc). selector app=shopp -> app=shop.
Erreur 3 - Port : targetPort 8080 alors que nginx écoute sur 80 (kubectl describe svc). targetPort -> 80.
```

`./labctl check 07` vérifie alors que l'application fonctionne de bout en bout et que le diagnostic traite bien les trois erreurs.

### 5. Bilan de tous les labs

```bash
$ ./labctl report
...
Rapport global : 43/105 points — note 8.2/20 (results/rapport.csv)

$ cat results/rapport.csv
lab;titre;points;max;note20
01;Mon premier Pod;8;10;16.0
02;Deployment et auto-réparation;11;15;14.7
03;Mise à jour progressive;0;15;0.0
04;Exposer une application avec un Service;5;13;7.7
05;ConfigMap et Secret;11;18;12.2
06;Sondes de santé et ressources;8;15;10.7
07;Diagnostic : réparer une application en panne;0;19;0.0
TOTAL;;43;105;8.2
```

Le fichier CSV s'ouvre directement dans un tableur. Le détail de chaque vérification est aussi enregistré en JSON, dans `results/labNN.json` :

```json
{"lab":"01","titre":"Mon premier Pod","points":10,"max":10,"note20":20.0,
 "date":"2026-11-19T22:05:01Z",
 "checks":[{"description":"Le conteneur utilise l'image nginx:1.25","points":2,"ok":true}, ...]}
```

### 6. Rendu par Git et correction automatique (GitHub Classroom)

L'étudiant dépose ses fichiers dans `rendu/` puis pousse :

```text
rendu/
├── lab01/pod-web.yaml
├── lab02/deploy-api.yaml
├── lab03/commandes.sh        # commandes kubectl (set image, annotate...)
├── lab04/svc-api.yaml
├── lab05/config.yaml
├── lab06/deploy-robust.yaml
└── lab07/
    ├── correctifs.sh
    └── diagnostic.txt
```

```bash
git add rendu && git commit -m "Rendu labs 01 à 07" && git push
```

Le workflow « Correction automatique » crée un cluster temporaire, prépare chaque lab, applique le rendu puis note le travail. L'enseignant récupère `rapport.csv` dans l'artefact `resultats`, depuis l'onglet **Actions**.

### 7. Côté enseignant : vérifier le didacticiel

```bash
# Sans cluster (kubectl simulé) : solutions = 20/20, état initial = 0, erreurs détectées
tests/run-tests.sh

# Sur un vrai cluster : appliquer les solutions puis vérifier
kind create cluster --name labs
git fetch origin solutions && git archive FETCH_HEAD solutions | tar -x
bash solutions/apply-all.sh
./labctl report        # attendu : 105/105 points — note 20.0/20
```

## Fonctionnement de la vérification automatique

Chaque `labs/labNN/check.sh` interroge l'API du cluster (`kubectl ... -o jsonpath`) et compare l'état réel à l'état attendu. Selon les labs, il fait aussi des **tests fonctionnels** : requête HTTP depuis un Pod temporaire, lecture des variables d'environnement, suppression d'un Pod pour tester l'auto-réparation. Chaque vérification ratée affiche la valeur obtenue, la valeur attendue et un indice. Les résultats sont enregistrés en JSON dans `results/`.

## Correction automatique des rendus (enseignant)

- `.github/workflows/autograding.yml` : à chaque push, un cluster kind éphémère est créé, les rendus de `rendu/labNN/` sont appliqués, puis tous les labs sont vérifiés. Le rapport est publié en artefact. Le workflow est compatible avec GitHub Classroom.
- `.github/workflows/selftest.yml` : vérifie que les solutions de référence obtiennent 20/20, ce qui garantit la cohérence du didacticiel.

## Solutions de référence

Les solutions ne sont pas dans la branche `main` : elles sont dans la branche **`solutions`**, qui ne contient que le dossier `solutions/`. Pour les récupérer dans votre copie de travail (le dossier est ignoré par Git sur `main`) :

```bash
git fetch origin solutions
git archive FETCH_HEAD solutions | tar -x
bash solutions/apply-all.sh   # applique toutes les solutions sur le cluster
```

## Tests du didacticiel

- `tests/run-tests.sh` exécute tous les scripts de vérification contre un **kubectl simulé**, sans cluster. Trois scénarios sont testés : solutions de référence (20/20 attendu à chaque lab), état de départ (0 point attendu, aucun point gratuit) et erreurs d'étudiant typiques (erreurs détectées attendues). Ce test est lancé à chaque push (`.github/workflows/tests.yml`).
- `.github/workflows/selftest.yml` (lancement manuel) refait le même contrôle sur un **vrai cluster** kind.

## Structure

```
labctl                 pilote (start / check / hint / reset / report)
lib/common.sh          primitives de vérification, notation, export JSON
labs/labNN/            README.md (énoncé), setup.sh, check.sh, hints.md
tests/                 kubectl simulé et tests hors cluster
rendu/                 dépôt des rendus étudiants
.github/workflows/     correction automatique et auto-test
```

## Ajouter un lab

Copier un dossier `labs/labNN`, écrire l'énoncé, puis le `check.sh` avec les primitives de `lib/common.sh` :

| Primitive | Usage |
|---|---|
| `require_exists KIND NOM "indice"` | la ressource doit exister (1 point), sinon arrêt du lab |
| `require_present KIND NOM "indice"` | idem, sans point (ressource créée par `setup.sh`) |
| `check_eq PTS "desc" "indice" "$obtenu" "attendu"` | égalité |
| `check_ge PTS "desc" "indice" "$obtenu" MIN` | valeur minimale |
| `check_contains PTS "desc" "indice" "$texte" "motif"` | motif présent (grep) |
| `check_nonempty PTS "desc" "indice" "$valeur"` | valeur non vide |
| `check_cmd PTS "desc" "indice" commande args...` | la commande réussit |

Exemple de `check.sh` minimal :

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/../../lib/common.sh"
lab_begin "08" "Mon nouveau lab" "lab08"

require_exists deployment app "Créez le Deployment 'app' dans lab08."

check_eq 2 "Le Deployment demande 2 réplicas" "Champ spec.replicas" \
  "$(jp deployment app '{.spec.replicas}')" "2"

check_cmd 3 "Le déploiement est terminé" "kubectl -n lab08 rollout status deploy/app" \
  kubectl -n lab08 rollout status deploy/app --timeout=90s

lab_end
```

Le barème du lab se calcule automatiquement à partir des points déclarés dans `check.sh`.
