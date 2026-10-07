#!/usr/bin/env bash
# Daily data-health check for one curve file.
# Usage: ./check_feed.sh 2026-09-03        Exit 0 = clean, 1 = issues found, 2 = usage error
set -euo pipefail

DATE="${1:?usage: $0 YYYY-MM-DD}"
DIR="${DATA_DIR:-lab/data/curves}"
TENORS="${TENORS_FILE:-lab/ref/tenors.txt}"
FILE="$DIR/sofr_ois_${DATE}.csv"
MAX_MOVE_BP=15
issues=0

flag() { echo "FAIL [$DATE] $*"; issues=$((issues+1)); }

# 1. File exists
if [[ ! -f "$FILE" ]]; then
  flag "file missing: $FILE"
  exit 1
fi

body=$(tail -n +2 "$FILE")

# 2. Missing tenors
missing=$(comm -23 <(sort "$TENORS") <(cut -d, -f2 <<< "$body" | sort -u) || true)
[[ -n "$missing" ]] && flag "missing tenors: $(tr '\n' ' ' <<< "$missing")"

# 3. Duplicate tenors
dups=$(cut -d, -f2 <<< "$body" | sort | uniq -d)
[[ -n "$dups" ]] && flag "duplicate tenors: $(tr '\n' ' ' <<< "$dups")"

# 4. Blank or implausible values (expect 0.5%..10%)
bad=$(awk -F, '$3=="" || $3<0.5 || $3>10 {print $2"="($3==""?"blank":$3)}' <<< "$body")
[[ -n "$bad" ]] && flag "bad values: $(tr '\n' ' ' <<< "$bad")"

# 5. Snapshot time
snaps=$(awk -F, '$5!="16:00" {print $2"@"$5}' <<< "$body")
[[ -n "$snaps" ]] && flag "off-snapshot: $(tr '\n' ' ' <<< "$snaps")"

# 6. Large moves vs previous available file
prev=$(ls "$DIR"/sofr_ois_*.csv | awk -v f="$FILE" '$0<f' | tail -1)
if [[ -n "$prev" ]]; then
  moves=$(awk -F, -v max="$MAX_MOVE_BP" '
      FNR==1 {next}
      NR==FNR {p[$2]=$3; next}
      ($2 in p) && $3!="" && p[$2]!="" { c=($3-p[$2])*100; if (c>max || c<-max) printf "%s %+.1fbp\n",$2,c }
    ' "$prev" "$FILE")
  [[ -n "$moves" ]] && flag "large moves vs $(basename "$prev"): $(tr '\n' ' ' <<< "$moves")"
fi

# 7. Stale: same value in each of the last 5 files (including today)
stale=$(ls "$DIR"/sofr_ois_*.csv | awk -v f="$FILE" '$0<=f' | tail -5 \
        | xargs awk -F, 'FNR>1 && $3!="" {seen[$2" "$3]++} END {for (k in seen) if (seen[k]==5) print k}')
[[ -n "$stale" ]] && flag "stale (unchanged 5 files): $(tr '\n' ' ' <<< "$stale")"

if (( issues == 0 )); then echo "OK   [$DATE]"; exit 0; else exit 1; fi
