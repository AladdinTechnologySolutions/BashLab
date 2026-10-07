# Bash Lab: Solutions and Interview Notes

All commands run from inside `lab/` unless stated. Outputs shown are what the lab dataset produces.

## The eight problems

| # | Date | Problem | Found by |
|---|---|---|---|
| 1 | 2026-08-21 | Whole file missing (feed timed out) | Q2, Q10 |
| 2 | 2026-08-12 | 7Y tenor missing | Q5, Q6 |
| 3 | 2026-08-18 | 3Y rate blank | Q7 |
| 4 | 2026-08-24 → 09-01 | 20Y stale for 7 files | Q14 |
| 5 | 2026-08-27 | 1Y in decimal, not percent (unit error) | Q11, Q12 |
| 6 | 2026-09-03 | 10Y bad print, +45.9bp then reverses | Q12, Q13 |
| 7 | 2026-09-08 | 5Y duplicated, BBG vs BGN disagree by 7bp | Q5, Q8 |
| 8 | 2026-09-10 | 2Y taken from 21:00 snapshot, not 16:00 | Q9, Q10 |

---

## Part A

**Q1**
```bash
ls data/curves | wc -l              # 29
wc -l < ref/business_days.txt       # 30
```

**Q2**
```bash
comm -23 ref/business_days.txt <(ls data/curves | sed -E 's/sofr_ois_(.*)\.csv/\1/')
# 2026-08-21
```
`comm -23` prints lines only in the first file. Both inputs must be sorted; ISO dates sort correctly as text, which is one reason to always use them in filenames. `<( ... )` is process substitution: it lets a command's output be used where a filename is expected.

**Q3**
```bash
head -5 "$(ls data/curves/*.csv | tail -1)"
```

**Q4**
```bash
find . -name '*.csv' -mtime -1
```

## Part B

**Q5**
```bash
for f in data/curves/*.csv; do
  n=$(( $(wc -l < "$f") - 1 ))
  [ "$n" -ne 12 ] && echo "$f $n"
done
# data/curves/sofr_ois_2026-08-12.csv 11
# data/curves/sofr_ois_2026-09-08.csv 13
```
`wc -l < file` prints just the number; `wc -l file` also prints the filename. Subtract one for the header.

**Q6**
```bash
comm -23 <(sort ref/tenors.txt) <(tail -n +2 data/curves/sofr_ois_2026-08-12.csv | cut -d, -f2 | sort)
# 7Y
```
`tenors.txt` is in curve order, not alphabetical, so it must be sorted for `comm`. Forgetting this is the classic `comm` bug: it gives wrong answers silently.

**Q7**
```bash
grep -H ',,' data/curves/*.csv
# data/curves/sofr_ois_2026-08-18.csv:2026-08-18,3Y,,BBG,16:00
```

**Q8**
```bash
tail -q -n +2 data/curves/*.csv | cut -d, -f1,2 | sort | uniq -d
# 2026-09-08,5Y
grep ',5Y,' data/curves/sofr_ois_2026-09-08.csv
# 2026-09-08,5Y,3.6277,BBG,16:00
# 2026-09-08,5Y,3.6977,BGN,16:00
```
Two sources, 7bp apart. A model would pick one arbitrarily, or average them, depending on how the loader works.

**Q9**
```bash
tail -q -n +2 data/curves/*.csv | cut -d, -f5 | sort | uniq -c
#     347 16:00
#       1 21:00
```
`sort | uniq -c` is the single most useful bash idiom for data work: a frequency table in one line. Add `| sort -rn` to rank it.

**Q10**
```bash
grep -c ERROR logs/feed_handler.log                                  # 6
grep ERROR logs/feed_handler.log | awk '{print $5}' | sort | uniq -c
#       2 AUTH
#       3 TIMEOUT
#       1 giving
grep 2026-08-21 logs/feed_handler.log
```
Three timeouts and a "giving up" on 2026-08-21 explain the missing file. The WARN lines also explain problems 2 and 8:
```bash
grep -E 'WARN|ERROR' logs/feed_handler.log | grep -v retry
```

## Part C

**Q11**
```bash
awk -F, 'FNR>1 && $3!="" && $3<1 {print FILENAME": "$0}' data/curves/*.csv
# data/curves/sofr_ois_2026-08-27.csv: 2026-08-27,1Y,0.039629,BBG,16:00
```
`FNR` is the line number within the current file, so `FNR>1` skips every header. `NR` would only skip the first file's header. The `$3!=""` guard matters: awk treats a blank as 0, which would otherwise be flagged too.

**Q12**
```bash
tail -q -n +2 data/curves/*.csv \
| sort -t, -k2,2 -k1,1 \
| awk -F, '$3!="" {
    if ($2==pt) { c=($3-pv)*100; if (c>15 || c<-15) printf "%s %s %+.1fbp\n", $1, $2, c }
    pt=$2; pv=$3
  }'
# 2026-09-03 10Y +45.9bp
# 2026-09-04 10Y -44.6bp
# 2026-08-27 1Y -392.6bp
# 2026-08-28 1Y +394.8bp
```
`sort -t, -k2,2 -k1,1` sorts by field 2 (tenor), then field 1 (date). `-k2,2` means "field 2 only"; plain `-k2` means "field 2 to end of line", which is a common mistake.

**Q13**
A jump followed by an equal reversal almost always means **one bad data point, not a market move**. A genuine repricing doesn't fully undo itself the next day. It also shows a weakness of simple day-on-day checks: one bad point produces two alerts, and the second one is on a perfectly good day.

**Q14**
```bash
tail -q -n +2 data/curves/*.csv \
| sort -t, -k2,2 -k1,1 \
| awk -F, '{
    if ($2==pt && $3==pv && $3!="") { run++ }
    else { if (run>=4) print pt, "stale from", start, "to", last, "(" run+1 " days)"; run=0; start=$1 }
    pt=$2; pv=$3; last=$1
  }
  END { if (run>=4) print pt, "stale from", start, "to", last, "(" run+1 " days)" }'
# 20Y stale from 2026-08-24 to 2026-09-01 (7 days)
```
The `END` block catches a stale run that lasts to the final row, which is easy to forget.

## Part D

**Q15** — see `check_feed.sh` in the lab folder. Points an interviewer will look for:

- `set -euo pipefail`: stop on errors (`-e`), fail on undefined variables (`-u`), and make a pipeline fail if any stage fails, not just the last (`pipefail`).
- `"${1:?usage...}"` fails fast with a message if no argument is given.
- `"${DATA_DIR:-lab/data/curves}"` gives a default that can be overridden by environment variable, so the same script runs in test and production.
- Meaningful exit codes, so cron, Airflow or CI can act on failure.
- Variables are always quoted (`"$FILE"`), so paths with spaces don't break.
- `|| true` after `comm`, because under `set -e` a command returning non-zero would otherwise kill the script.

Running it over the stale run shows a design limitation worth discussing: the stale check needs 5 files, so it only fires from 2026-08-28, four days after the problem started. Shorter windows catch it sooner but give false positives on genuinely quiet tenors. That trade-off is a good interview answer in itself.

**Q16**
```bash
ok=0; bad=0; failed=()
while read -r d; do
  if ./check_feed.sh "$d" > /dev/null; then ok=$((ok+1)); else bad=$((bad+1)); failed+=("$d"); fi
done < lab/ref/business_days.txt
echo "clean: $ok  failing: $bad"; printf '%s\n' "${failed[@]}"
# clean: 19  failing: 11
```
(Run from the folder containing `check_feed.sh`.) Note `if command; then` tests the exit code directly, which is cleaner than checking `$?` afterwards.

## Part E

**Q17**
```cron
30 17 * * 1-5 cd /path/to/project && ./check_feed.sh "$(date +\%F)" >> logs/health.log 2>&1
```
- `%` must be escaped as `\%` in crontab, or cron treats it as a newline. This is the trap.
- `>> file 2>&1` appends stdout, then sends stderr to the same place. Order matters: `2>&1 >> file` would leave stderr on the terminal.
- Cron runs in the server's time zone, with a minimal `PATH`, not your login shell. Use absolute paths, and check the server's time zone given London's clock changes.

**Q18**
```bash
tail -f logs/feed_handler.log | grep --line-buffered -E 'WARN|ERROR'
```
`--line-buffered` makes `grep` print each match immediately instead of waiting to fill a buffer, which matters when piping a live stream.

**Q19**
```bash
git init && git add check_feed.sh && git commit -m "Add daily curve data health check"
git switch -c add-zscore-check        # or: git checkout -b add-zscore-check
# ...edit...
git commit -am "Add rolling z-score move check"
git switch main && git merge add-zscore-check
```

---

## Quick-fire interview questions

| Question | Short answer |
|---|---|
| `>` vs `>>` | Overwrite vs append. |
| What does `2>&1` do? | Redirects stderr (2) to wherever stdout (1) currently points. |
| `$?` | Exit code of the last command; 0 means success. |
| `&&` vs `;` | `&&` runs the next command only if the previous succeeded; `;` always runs it. |
| Single vs double quotes | Double quotes expand `$VAR` and `$(...)`; single quotes are literal. |
| Find the 10 largest files under a folder | `du -ah dir \| sort -rh \| head -10` |
| Count unique values in column 3 of a CSV | `cut -d, -f3 file \| sort \| uniq -c \| sort -rn` |
| Replace text in place across files | `sed -i 's/old/new/g' *.csv` (on macOS: `sed -i ''`) |
| Run a job that survives logout | `nohup cmd &`, or better, `tmux`/`screen` |
| What's using this port / CPU? | `ps aux \| grep name`, `top`/`htop`, `lsof -i :8080` |
| Why can't `wc -l` alone count CSV records? | Quoted fields can contain newlines; a real CSV parser is needed for messy data. |

The last question is a good one to raise unprompted. It shows you know where bash stops being the right tool, which is exactly the judgement a data science team wants.
