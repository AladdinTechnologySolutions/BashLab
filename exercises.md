# Bash Lab: Market Data Health Check

## Scenario

You've joined the data science team at a systematic fund. A feed handler pulls end-of-day SOFR OIS rates (12 tenors, ON to 30Y) from a vendor at 16:00 London and writes one CSV per business day. Six weeks of files have landed. Some of them have problems. Leadership wants to know what is wrong before the data reaches the models, and wants the check automated.

Everything below must be done with bash and standard Unix tools: `ls`, `find`, `wc`, `head`, `tail`, `grep`, `cut`, `sort`, `uniq`, `comm`, `sed`, `awk`, `xargs`, loops. No Python.

## Setup

```bash
bash setup_lab.sh
cd lab
```

You will have:

| Path | Contents |
|---|---|
| `data/curves/sofr_ois_YYYY-MM-DD.csv` | One file per day: `date,tenor,rate_pct,source,snapshot_time` |
| `ref/business_days.txt` | Every business day the feed should have produced |
| `ref/tenors.txt` | The 12 tenors every file should contain |
| `logs/feed_handler.log` | The feed handler's log |

There are **eight** distinct data problems hidden in the files. Find them all.

---

## Part A: Orientation (Day 1 skills)

1. How many curve files are there? How many business days should there be?
2. Which business day has no file? (Hint: `comm` compares two sorted lists. You'll need to strip the filename down to the date.)
3. Show the first 5 lines of the most recent file without opening an editor.
4. Find every `.csv` file under `lab/` modified in the last day, using `find`.

## Part B: Filtering and counting (Day 2 skills)

5. Every file should have exactly 12 data rows. Which files don't, and how many rows do they have? (A `for` loop plus `wc -l`.)
6. Which file is missing a tenor, and which tenor?
7. Find any row with a blank rate.
8. Find any date and tenor combination that appears more than once. What's different between the two rows?
9. Count how many rows were captured at each `snapshot_time`. Which one is wrong?
10. In the log, count the ERROR lines, then break them down by error type. Which error explains the missing file from question 2?

## Part C: awk (Day 3 skills)

11. Rates are in percent, so any value below 1 is almost certainly a unit error. Find it with `awk`, printing the filename too.
12. Compute the day-on-day change per tenor in basis points across all files and print every move larger than 15bp.
    Hint: concatenate all files without headers (`tail -q -n +2`), sort by tenor then date, and let `awk` remember the previous row.
13. Look at the output of question 12. One problem shows up as a jump on one day followed by an almost identical reversal the next. What does that pattern usually mean?
14. Detect stale quotes: any tenor whose value is identical for 5 or more consecutive files. Report the tenor and the date range.

## Part D: Scripting (Day 4 skills)

15. Write `check_feed.sh` that takes one date as an argument and checks that day's file for:
    - file missing
    - missing or duplicate tenors
    - blank or implausible values (outside 0.5%–10%)
    - snapshot time other than 16:00
    - moves over 15bp versus the previous available file
    - a value unchanged across the last 5 files

    Requirements: `set -euo pipefail`; print one `FAIL [date] reason` line per issue or `OK [date]`; **exit 0 if clean, 1 if any issue**; paths configurable through environment variables with sensible defaults.
16. Loop over every business day, run your script, and produce a summary: number of clean days, number of failing days, and the list of failing dates.

## Part E: Automation (Day 5 skills)

17. Write the crontab line that runs `check_feed.sh` for today's date at 17:30 every weekday and appends both stdout and stderr to `logs/health.log`. (There is a well-known trap with `%` in crontab.)
18. How would you watch `logs/feed_handler.log` live as the 16:00 run happens, showing only warnings and errors?
19. Put `check_feed.sh` under git: initialise a repo, commit, create a branch `add-zscore-check`, make a change, and merge it back.

---

## Stretch

- Replace the fixed 15bp threshold with a rolling one: flag a move if it's more than 4 standard deviations of that tenor's last 20 daily changes.
- The 2026-09-08 duplicate comes from two different sources (BBG and BGN). Extend the script to report the disagreement between sources in basis points.
- Explain, in two sentences each, why each of the eight problems would matter if it reached a curve-building or trading model.
