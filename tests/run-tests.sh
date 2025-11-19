#!/usr/bin/env bash
# Tests hors cluster des scripts de vérification, avec un kubectl simulé.
#  - « solved »  : les solutions de référence doivent obtenir 20/20 à chaque lab ;
#  - « initial » : sans travail de l'étudiant, le total doit être 0 (aucun point gratuit) ;
#  - « wrong »   : des erreurs typiques doivent être détectées (note < 20).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -f "$ROOT/labs/lab07/diagnostic.txt"; rm -rf -- "$TMP"' EXIT
# Solutions de référence : dossier local solutions/ s'il existe, sinon la branche « solutions ».
if [ -d "$ROOT/solutions" ]; then
  SOL="$ROOT/solutions"
else
  git -C "$ROOT" fetch -q --depth=1 origin solutions 2>/dev/null
  if ! git -C "$ROOT" archive FETCH_HEAD solutions 2>/dev/null | tar -x -C "$TMP"; then
    echo "Solutions introuvables : branche « solutions » inaccessible." >&2; exit 1
  fi
  SOL="$TMP/solutions"
fi
python3 "$ROOT/tests/build_states.py" "$ROOT" "$TMP" "$SOL" >/dev/null || exit 1
export PATH="$ROOT/tests/sim:$PATH" NO_COLOR=1
fail=0

run() { SIM_STATE="$TMP/$1.json" RESULTS_DIR="$TMP/res-$1" "$ROOT/labctl" report >"$TMP/$1.log" 2>&1; }

sed -n '/<<.TXT./,/^TXT/p' "$SOL/lab07.sh" | sed '1d;$d' > "$ROOT/labs/lab07/diagnostic.txt"
run solved
while IFS=';' read -r lab _ pts max _; do
  [ "$lab" = "lab" ] && continue
  if [ "$pts" = "$max" ]; then echo "OK   solved  lab $lab : $pts/$max"; else echo "FAIL solved  lab $lab : $pts/$max"; fail=1; fi
done < "$TMP/res-solved/rapport.csv"
rm -f "$ROOT/labs/lab07/diagnostic.txt"

run initial
tot=$(grep '^TOTAL' "$TMP/res-initial/rapport.csv" | cut -d';' -f3)
if [ "$tot" = "0" ]; then echo "OK   initial total : 0 point"; else echo "FAIL initial total : $tot points gratuits"; fail=1; fi

run wrong
for lab in 01 02 04 05 06; do
  note=$(grep "^$lab;" "$TMP/res-wrong/rapport.csv" | cut -d';' -f5)
  if awk "BEGIN{exit !($note < 20)}"; then echo "OK   wrong   lab $lab : erreurs détectées ($note/20)"; else echo "FAIL wrong   lab $lab : erreurs non détectées"; fail=1; fi
done

if grep -h "simulateur : commande non gérée" "$TMP"/*.log; then fail=1; fi
[ "$fail" = 0 ] && echo "Tous les tests passent." || echo "Des tests échouent (journaux : $TMP)."
exit "$fail"
