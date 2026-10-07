#!/usr/bin/env bash
# Builds the practice dataset for the bash market-data exercise.
# Usage: bash setup_lab.sh        (creates ./lab/ in the current directory)
set -euo pipefail

rm -rf lab && mkdir -p lab/data/curves lab/logs lab/ref

python3 - << 'PY'
import random, datetime as dt, os
random.seed(42)

tenors = ["ON","1M","3M","6M","1Y","2Y","3Y","5Y","7Y","10Y","20Y","30Y"]
base   = [4.31,4.30,4.25,4.12,3.95,3.72,3.63,3.60,3.68,3.82,4.05,4.01]

days, d = [], dt.date(2026,8,3)
while d <= dt.date(2026,9,11):
    if d.weekday() < 5: days.append(d)
    d += dt.timedelta(days=1)

with open("lab/ref/business_days.txt","w") as f:
    f.write("\n".join(x.isoformat() for x in days) + "\n")

with open("lab/ref/tenors.txt","w") as f:
    f.write("\n".join(tenors) + "\n")

rates = base[:]
stale_val = None
for d in days:
    ds = d.isoformat()
    common = random.gauss(0, 0.02)
    rates = [r + common + random.gauss(0, 0.005) for r in rates]
    if ds == "2026-08-21":          # whole file missing
        continue
    rows = []
    for t, r in zip(tenors, rates):
        val, snap, src = round(r, 4), "16:00", "BBG"
        if ds == "2026-08-12" and t == "7Y":   continue                 # missing tenor
        if t == "20Y" and "2026-08-24" <= ds <= "2026-09-01":            # stale quote
            stale_val = stale_val or val; val = stale_val
        if ds == "2026-09-03" and t == "10Y":  val = round(val + 0.45, 4)  # bad print
        if ds == "2026-08-27" and t == "1Y":   val = round(val / 100, 6)   # unit error
        if ds == "2026-09-10" and t == "2Y":   snap = "21:00"              # wrong snapshot
        sval = "" if (ds == "2026-08-18" and t == "3Y") else str(val)       # blank value
        rows.append(f"{ds},{t},{sval},{src},{snap}")
        if ds == "2026-09-08" and t == "5Y":                                # conflicting duplicate
            rows.append(f"{ds},{t},{round(val+0.07,4)},BGN,16:00")
    with open(f"lab/data/curves/sofr_ois_{ds}.csv","w") as f:
        f.write("date,tenor,rate_pct,source,snapshot_time\n" + "\n".join(rows) + "\n")

# feed handler log
lines = []
for d in days:
    ds = d.isoformat()
    lines.append(f"{ds} 15:58:01 INFO  feed_handler: session start")
    lines.append(f"{ds} 16:00:02 INFO  feed_handler: requesting 12 tenors")
    if ds == "2026-08-21":
        lines += [f"{ds} 16:00:32 ERROR feed_handler: TIMEOUT after 30s",
                  f"{ds} 16:01:02 WARN  feed_handler: retry 1/3",
                  f"{ds} 16:01:32 ERROR feed_handler: TIMEOUT after 30s",
                  f"{ds} 16:02:02 WARN  feed_handler: retry 2/3",
                  f"{ds} 16:02:32 ERROR feed_handler: TIMEOUT after 30s",
                  f"{ds} 16:02:33 ERROR feed_handler: giving up, no file written"]
    elif ds == "2026-08-12":
        lines.append(f"{ds} 16:00:05 WARN  feed_handler: field rate_pct not returned for tenor 7Y")
    elif ds == "2026-09-10":
        lines.append(f"{ds} 21:00:04 WARN  feed_handler: late response for tenor 2Y, used evening snapshot")
    elif ds in ("2026-08-05","2026-09-02"):
        lines.append(f"{ds} 16:00:09 ERROR feed_handler: AUTH token expired, refreshed")
    lines.append(f"{ds} 16:00:10 INFO  feed_handler: wrote file")
with open("lab/logs/feed_handler.log","w") as f:
    f.write("\n".join(lines) + "\n")
PY

echo "Lab ready in ./lab"
find lab -type f | sort | head -5; echo "..."
