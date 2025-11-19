#!/usr/bin/env bash
# =====================================================================
#  Bibliothèque commune des scripts de vérification (check.sh)
#  Labs Kubernetes guidés — vérification automatique
# =====================================================================
# Chaque check.sh :
#   1. source ce fichier ;
#   2. appelle lab_begin "<id>" "<titre>" "<namespace>" ;
#   3. enchaîne des vérifications (check_eq, check_ge, check_cmd...) ;
#   4. termine par lab_end (affiche le score, écrit results/labXX.json).
# Dépendance : kubectl configuré sur un cluster (kind, minikube, k3d...).
# =====================================================================

set -u

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$LIB_DIR/.." && pwd)"
RESULTS_DIR="${RESULTS_DIR:-$ROOT_DIR/results}"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  GREEN=$'\e[32m'; RED=$'\e[31m'; YEL=$'\e[33m'; BOLD=$'\e[1m'; DIM=$'\e[2m'; RST=$'\e[0m'
else
  GREEN=""; RED=""; YEL=""; BOLD=""; DIM=""; RST=""
fi

LAB_ID=""; LAB_TITLE=""; NS=""
_POINTS=0; _MAX=0; _NB_OK=0; _NB=0
_JSON_CHECKS=""

# --- Accès au cluster -------------------------------------------------

require_cluster() {
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "${RED}kubectl introuvable. Installez-le puis relancez.${RST}" >&2
    exit 2
  fi
  if ! kubectl get nodes >/dev/null 2>&1; then
    echo "${RED}Cluster injoignable. Démarrez votre cluster (ex. : kind create cluster --name labs).${RST}" >&2
    exit 2
  fi
}

# jp KIND NAME JSONPATH  -> valeur (vide si absente)
jp() { kubectl -n "$NS" get "$1" "$2" -o "jsonpath=$3" 2>/dev/null; }

# exists KIND NAME
exists() { kubectl -n "$NS" get "$1" "$2" >/dev/null 2>&1; }

# count_words "texte" -> nombre de mots
count_words() { echo "$1" | wc -w | tr -d ' '; }

# --- Enregistrement des résultats -------------------------------------

_json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }

_record() { # _record PTS OK(0|1) DESC HINT DETAIL
  local pts=$1 ok=$2 desc=$3 hint=$4 detail=${5:-}
  _MAX=$(awk "BEGIN{print $_MAX + $pts}")
  _NB=$((_NB + 1))
  if [ "$ok" = "1" ]; then
    _POINTS=$(awk "BEGIN{print $_POINTS + $pts}")
    _NB_OK=$((_NB_OK + 1))
    printf '  %s[OK]%s %s %s(+%s)%s\n' "$GREEN" "$RST" "$desc" "$DIM" "$pts" "$RST"
  else
    printf '  %s[KO]%s %s %s(0/%s)%s\n' "$RED" "$RST" "$desc" "$DIM" "$pts" "$RST"
    [ -n "$detail" ] && printf '      %s%s%s\n' "$DIM" "$detail" "$RST"
    [ -n "$hint" ]   && printf '      %sIndice : %s%s\n' "$YEL" "$hint" "$RST"
  fi
  local sep=""; [ -n "$_JSON_CHECKS" ] && sep=","
  _JSON_CHECKS="${_JSON_CHECKS}${sep}{\"description\":\"$(_json_escape "$desc")\",\"points\":$pts,\"ok\":$([ "$ok" = 1 ] && echo true || echo false)}"
}

# --- Primitives de vérification ---------------------------------------

# check_eq PTS "description" "indice" "valeur obtenue" "valeur attendue"
check_eq() {
  local pts=$1 desc=$2 hint=$3 actual=$4 expected=$5
  if [ "$actual" = "$expected" ]; then _record "$pts" 1 "$desc" "$hint"
  else _record "$pts" 0 "$desc" "$hint" "obtenu : '${actual:-<vide>}' — attendu : '$expected'"; fi
}

# check_ge PTS "description" "indice" "valeur obtenue" minimum
check_ge() {
  local pts=$1 desc=$2 hint=$3 actual=${4:-0} min=$5
  [[ "$actual" =~ ^[0-9]+$ ]] || actual=0
  if [ "$actual" -ge "$min" ]; then _record "$pts" 1 "$desc" "$hint"
  else _record "$pts" 0 "$desc" "$hint" "obtenu : $actual — minimum attendu : $min"; fi
}

# check_nonempty PTS "description" "indice" "valeur"
check_nonempty() {
  local pts=$1 desc=$2 hint=$3 actual=$4
  if [ -n "$actual" ]; then _record "$pts" 1 "$desc" "$hint"
  else _record "$pts" 0 "$desc" "$hint" "valeur absente"; fi
}

# check_contains PTS "description" "indice" "texte" "motif"
check_contains() {
  local pts=$1 desc=$2 hint=$3 text=$4 pattern=$5
  if printf '%s' "$text" | grep -q -- "$pattern"; then _record "$pts" 1 "$desc" "$hint"
  else _record "$pts" 0 "$desc" "$hint" "motif '$pattern' non trouvé"; fi
}

# check_cmd PTS "description" "indice" commande [args...]  (succès = code retour 0)
check_cmd() {
  local pts=$1 desc=$2 hint=$3; shift 3
  if "$@" >/dev/null 2>&1; then _record "$pts" 1 "$desc" "$hint"
  else _record "$pts" 0 "$desc" "$hint"; fi
}

# require_exists KIND NAME "indice" : arrête le lab proprement si la ressource de base manque
require_exists() {
  local kind=$1 name=$2 hint=$3
  if exists "$kind" "$name"; then
    _record 1 1 "La ressource $kind/$name existe dans le namespace $NS" "$hint"
  else
    _record 1 0 "La ressource $kind/$name existe dans le namespace $NS" "$hint"
    echo "  ${YEL}Les vérifications suivantes dépendent de cette ressource : arrêt du lab.${RST}"
    lab_end
  fi
}

# require_present KIND NAME "indice" : comme require_exists, mais sans point
# (ressource fournie par setup.sh : sa présence ne prouve aucun travail).
require_present() {
  local kind=$1 name=$2 hint=$3
  if ! exists "$kind" "$name"; then
    printf '  %s[KO]%s La ressource %s/%s est absente du namespace %s\n' "$RED" "$RST" "$kind" "$name" "$NS"
    printf '      %sIndice : %s%s\n' "$YEL" "$hint" "$RST"
    echo "  ${YEL}Les vérifications suivantes dépendent de cette ressource : arrêt du lab.${RST}"
    lab_end
  fi
}

# --- Début / fin de lab -----------------------------------------------

lab_begin() {
  LAB_ID=$1; LAB_TITLE=$2; NS=$3
  # Barème complet du lab, lu dans le script appelant : une vérification
  # non exécutée (arrêt anticipé) compte 0 sans réduire le total.
  LAB_FULL_MAX=$(grep -E '^\s*(check_[a-z]+|require_exists)\b' "$0" \
    | awk '{ if ($1=="require_exists") t+=1; else t+=$2 } END{print t+0}')
  require_cluster
  echo
  echo "${BOLD}Lab $LAB_ID — $LAB_TITLE${RST}  ${DIM}(namespace : $NS)${RST}"
  echo "${DIM}--------------------------------------------------------------${RST}"
}

lab_end() {
  local note
  if [ "${LAB_FULL_MAX:-0}" != "0" ] && awk "BEGIN{exit !($LAB_FULL_MAX > $_MAX)}"; then
    _NB=$((_NB + 1))   # au moins une vérification non exécutée
    _MAX=$LAB_FULL_MAX
  fi
  note=$(awk "BEGIN{ if ($_MAX>0) printf \"%.1f\", 20*$_POINTS/$_MAX; else print 0 }")
  echo "${DIM}--------------------------------------------------------------${RST}"
  if [ "$_NB_OK" -eq "$_NB" ]; then
    echo "${GREEN}${BOLD}Lab $LAB_ID réussi : $_POINTS/$_MAX points — note $note/20${RST}"
  else
    echo "${YEL}${BOLD}Lab $LAB_ID : $_POINTS/$_MAX points — note $note/20 ($_NB_OK/$_NB vérifications)${RST}"
    echo "${DIM}Corrigez puis relancez : ./labctl check $LAB_ID${RST}"
  fi
  mkdir -p "$RESULTS_DIR"
  cat > "$RESULTS_DIR/lab$LAB_ID.json" <<EOF
{"lab":"$LAB_ID","titre":"$(_json_escape "$LAB_TITLE")","points":$_POINTS,"max":$_MAX,"note20":$note,"date":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","checks":[$_JSON_CHECKS]}
EOF
  [ "$_NB_OK" -eq "$_NB" ] && exit 0 || exit 1
}
