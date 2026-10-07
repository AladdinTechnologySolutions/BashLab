# Bash in 5 Days: Daily Practice Guide

This guide takes you from zero to writing a production-style data-quality script in bash, in five sessions of about 1.5–2 hours each. Every exercise uses the same realistic dataset: six weeks of daily SOFR OIS curve files from a market-data feed, plus the feed handler's log.

The final goal is the kind of work a data scientist does at a systematic fund: checking that market data is correct before it reaches models, and automating that check.

## How to use this guide

- **Type every command yourself.** Don't copy and paste. The aim is muscle memory, and typing mistakes teach you what the errors look like.
- **Predict before you press Enter.** Say out loud what you expect the command to show, then check. When you're wrong, work out why before moving on.
- **Answers are hidden.** Click "Answer" to reveal one, but only after you've genuinely tried.
- **Each day starts with a 5-minute warm-up** on the previous day's commands, and ends with one part of the lab exercise (`exercises.md`).
- When you're stuck on a command, try `man grep` (press `q` to quit), `grep --help`, or search the command name plus your problem.

| Day | Topic | Lab part at the end |
|---|---|---|
| 1 | Navigation and files | Part A |
| 2 | Filtering and counting | Part B |
| 3 | awk | Part C |
| 4 | Scripting | Part D |
| 5 | Automation, processes and git | Part E |

---

## One-off setup (about 20 minutes, before Day 1)

### 1. Get a bash terminal

- **macOS or Linux:** you already have one. Open VS Code and press **Ctrl+`** (backtick) to open the terminal. On a Mac the default shell is zsh, which behaves the same for almost everything here. To use bash itself, click the **˅** next to **+** in the terminal panel and choose **bash**.
- **Windows:** the default terminal is PowerShell, which won't work. Install one of:
  - **WSL** (recommended, it's real Linux): in an *administrator* PowerShell run `wsl --install`, restart, install the **WSL** extension in VS Code, then choose **Connect to WSL**.
  - **Git Bash** (quicker): install Git for Windows from git-scm.com, restart VS Code, then in the terminal panel click **˅** → **Select Default Profile** → **Git Bash**.

Use a personal laptop. Bank-managed machines often block WSL and admin rights, and installing tools may breach IT policy.

### 2. Check it works

```bash
echo $0
which grep awk sed
python3 --version
```

You should see `bash` (or `-bash`), three paths like `/usr/bin/grep`, and a Python 3 version. If `python3` isn't found on Git Bash, try `python --version`; if that works, open `setup_lab.sh` and change `python3` to `python` on the line that starts with `python3 -`.

### 3. Create your course folder and the dataset

```bash
mkdir -p ~/bash-course
cd ~/bash-course
```

Put `setup_lab.sh` and `exercises.md` into `~/bash-course` (drag them in from your Downloads folder, or use `mv ~/Downloads/setup_lab.sh .` once you know `mv` on Day 1). Then:

```bash
bash setup_lab.sh
```

You should see "Lab ready in ./lab". Your layout is now:

```
~/bash-course/
├── setup_lab.sh          builds the dataset (re-run any time to reset it)
├── exercises.md          the lab questions
└── lab/
    ├── data/curves/      sofr_ois_YYYY-MM-DD.csv, one per business day
    ├── logs/             feed_handler.log
    └── ref/              business_days.txt, tenors.txt
```

If you ever break or delete something in `lab/`, just run `bash setup_lab.sh` again from `~/bash-course` to rebuild it.

### 4. Know the data

Each curve file looks like this:

```
date,tenor,rate_pct,source,snapshot_time
2026-09-03,ON,4.3753,BBG,16:00
2026-09-03,1M,4.3186,BBG,16:00
...
```

- `tenor`: one of 12 maturities, ON (overnight) to 30Y
- `rate_pct`: the rate in percent, so 4.3753 means 4.3753%
- `source`: BBG (Bloomberg) or another vendor code
- `snapshot_time`: when the price was captured; it should be 16:00 London

**The data has deliberate problems in it.** Finding them is the lab. Don't go hunting yet; the daily practice will give you the tools.

---

# Day 1: Navigation and Files

**Goal:** move around confidently, create and manage files, look inside files without opening an editor, and understand permissions.
**Time:** about 90 minutes.
**Commands:** `pwd`, `ls`, `cd`, `mkdir`, `touch`, `cp`, `mv`, `rm`, wildcards, `cat`, `head`, `tail`, `wc`, `less`, `find`, `chmod`

## 1.1 Where am I? (15 min)

```bash
cd ~/bash-course
pwd                      # print the full path of where you are
ls                       # list contents
ls -l                    # long format: permissions, owner, size, date
ls -lh                   # same, with human-readable sizes (K, M)
ls -a                    # include hidden files (names starting with .)
ls -lt                   # newest first
ls -ltr                  # oldest first (r = reverse)
ls lab                   # list a folder without going into it
ls -R lab                # list everything below, recursively
```

Now move around:

```bash
cd lab                   # relative path: "lab, inside where I am now"
pwd
cd data/curves
pwd
cd ..                    # up one level
pwd
cd ../..                 # up two levels
pwd
cd -                     # jump back to where you just were
cd ~                     # your home directory (plain `cd` does the same)
```

**Absolute versus relative paths.** An absolute path starts with `/` (or `~`, meaning your home folder) and works from anywhere. A relative path is interpreted from where you are now.

```bash
cd ~/bash-course/lab/data/curves   # absolute: works from anywhere
cd ../../logs                      # relative: only works from the right place
pwd
```

**Tab completion** is the most important habit of the day. Type `cd ~/bash-course/lab/da` and press **Tab**: it completes the name. Press Tab twice to see every option when there's more than one. Use it for every path from now on; it halves typing errors.

**Up arrow** recalls previous commands. **Ctrl+R** then typing part of a command searches your history. **Ctrl+C** cancels whatever is running. **Ctrl+L** clears the screen.

### Practice 1

From your home directory, without using Tab yet:

1. Go to `~/bash-course/lab/data/curves` in one command.
2. From there, go to `lab/logs` using a relative path.
3. From there, go to `lab/ref` using a relative path.
4. Go back to `lab/logs` with a two-character command.
5. List `lab/data/curves` with sizes, newest first, without leaving `lab/logs`.

<details><summary>Answer</summary>

```bash
cd ~/bash-course/lab/data/curves
cd ../../logs
cd ../ref
cd -
ls -lht ../data/curves
```
</details>

## 1.2 Creating, copying, moving and deleting (15 min)

Work in a scratch area so the lab data stays intact:

```bash
cd ~/bash-course/lab
mkdir scratch
mkdir -p scratch/2026/09/raw     # -p creates every missing parent folder, and doesn't fail if it exists
ls -R scratch

touch scratch/notes.txt          # create an empty file (or update an existing file's timestamp)
ls -l scratch

cp data/curves/sofr_ois_2026-09-03.csv scratch/          # copy a file into a folder
cp scratch/sofr_ois_2026-09-03.csv scratch/backup.csv    # copy with a new name
cp -r data/curves scratch/curves_copy                    # -r copies a whole folder
ls scratch

mv scratch/backup.csv scratch/old.csv       # mv renames...
mv scratch/old.csv scratch/2026/09/raw/     # ...and moves
ls -R scratch
```

Delete carefully:

```bash
rm scratch/notes.txt
rm -i scratch/sofr_ois_2026-09-03.csv   # -i asks before deleting; answer y
rm scratch/curves_copy                  # fails: it's a directory
rm -r scratch/curves_copy               # -r removes a folder and everything inside it
ls scratch
```

> **Warning:** there is no recycle bin. `rm` is permanent, and `rm -r` on the wrong path is the classic disaster. Before any `rm -r`, run `ls` on the same path first and read the output.

### Practice 2

1. Create `scratch/reports/daily` and `scratch/reports/weekly` with a single `mkdir` command. (Hint: you can give `mkdir` more than one path.)
2. Copy the 1 September curve file into `daily`, renamed `latest.csv`.
3. Rename `weekly` to `monthly`.
4. Delete the whole `reports` folder, checking it first.

<details><summary>Answer</summary>

```bash
mkdir -p scratch/reports/daily scratch/reports/weekly
cp data/curves/sofr_ois_2026-09-01.csv scratch/reports/daily/latest.csv
mv scratch/reports/weekly scratch/reports/monthly
ls -R scratch/reports
rm -r scratch/reports
```
</details>

## 1.3 Wildcards (15 min)

The shell expands wildcards into a list of matching filenames *before* the command runs. The command never sees the `*`.

```bash
cd ~/bash-course/lab/data/curves

ls *.csv                           # * = any characters (including none)
ls sofr_ois_2026-09-*.csv          # all September files
ls sofr_ois_2026-09-*.csv | wc -l  # count them (wc is covered below)
ls sofr_ois_2026-08-1?.csv         # ? = exactly one character: 10th–19th August
ls sofr_ois_2026-0[89]-0*.csv      # [89] = one character, either 8 or 9
ls sofr_ois_2026-08-2[4-8].csv     # [4-8] = one character in that range
ls sofr_ois_2026-09-{03,04}.csv    # {a,b} = each listed alternative
echo *.csv                         # shows exactly what the shell expanded to
```

> **Habit:** before using a wildcard with `rm` or `mv`, run the same pattern with `ls` or `echo` first to see exactly which files it matches.

### Practice 3

From `lab/data/curves`:

1. List only the files from the first five days of September that exist.
2. Count how many August files there are.
3. Copy every file from the week of 24–28 August into `~/bash-course/lab/scratch/week35/` (create it first).
4. List the files dated the 10th, 20th or 30th of any month.

<details><summary>Answer</summary>

```bash
ls sofr_ois_2026-09-0[1-5].csv                 # 1, 2, 3, 4 exist; the 5th was a Saturday
ls sofr_ois_2026-08-*.csv | wc -l              # 20
mkdir -p ../../scratch/week35
cp sofr_ois_2026-08-2[4-8].csv ../../scratch/week35/
ls ../../scratch/week35                        # 5 files
ls sofr_ois_2026-*-[123]0.csv
```
</details>

## 1.4 Looking inside files (20 min)

```bash
cd ~/bash-course/lab/data/curves

cat sofr_ois_2026-09-03.csv          # print the whole file (fine for small files only)
head sofr_ois_2026-09-03.csv         # first 10 lines
head -n 3 sofr_ois_2026-09-03.csv    # first 3 lines
tail -n 3 sofr_ois_2026-09-03.csv    # last 3 lines
tail -n +2 sofr_ois_2026-09-03.csv   # everything FROM line 2 onwards, i.e. skip the header
```

`tail -n +2` is the standard way to drop a CSV header. You'll use it every day from now on.

Counting with `wc` (word count):

```bash
wc sofr_ois_2026-09-03.csv           # lines, words, bytes, filename
wc -l sofr_ois_2026-09-03.csv        # lines only, with the filename
wc -l < sofr_ois_2026-09-03.csv      # lines only, just the number
wc -l *.csv                          # every file, plus a total at the end
tail -n +2 sofr_ois_2026-09-03.csv | wc -l   # data rows only: 12
```

The `|` (pipe) sends the output of one command into the next. Day 2 is built around it.

**Your first data-quality observation:** look at the output of `wc -l *.csv`. A healthy file has 13 lines (12 tenors plus a header). Do they all? Note what you see, but don't investigate yet; that's in the lab.

### Reading large files with `less`

```bash
less ../../logs/feed_handler.log
```

Keys inside `less`:

| Key | Action |
|---|---|
| Space / b | forward / back one page |
| ↓ / ↑ | one line |
| `/TIMEOUT` then Enter | search forward |
| `n` / `N` | next / previous match |
| `G` / `g` | end / start of file |
| `q` | quit |

Search for `TIMEOUT` and note which date it happened on. Then search for `WARN`.

### Following a growing file

```bash
tail -f ../../logs/feed_handler.log    # Ctrl+C to stop
```

Nothing changes here because the file is static, but this is how you watch a live feed or application log as it's written. To see it work, open a **second terminal** (click **+** in VS Code's terminal panel) and run:

```bash
echo "$(date +%T) TEST manual line" >> ~/bash-course/lab/logs/feed_handler.log
```

The new line appears in the first terminal immediately. (Re-run `setup_lab.sh` later if you want a clean log.)

## 1.5 Finding files with `find` (10 min)

`ls` lists one folder. `find` searches a whole tree, with conditions.

```bash
cd ~/bash-course/lab
find .                                  # everything below here (. means "current folder")
find . -type f                          # files only
find . -type d                          # directories only
find . -name '*.log'                    # by name pattern
find . -name 'sofr_ois_2026-09-*'       # September curve files, wherever they are
find . -type f -mtime -1                # modified in the last day
find . -type f -size +1k                # bigger than 1 KB
find . -name '*.csv' | wc -l            # count every CSV, including copies in scratch
find data -name '*.csv' -exec wc -l {} \;   # run a command on each file found
```

> **Always quote the pattern** in `find -name '*.csv'`. Without quotes, the shell may expand `*.csv` itself before `find` runs, and `find` receives the wrong arguments.

In `-exec wc -l {} \;`, the `{}` is replaced by each filename and `\;` marks the end of the command.

## 1.6 Permissions and `chmod` (10 min)

```bash
cd ~/bash-course
mkdir -p practice
cd practice
printf '#!/usr/bin/env bash\necho "hello from $0"\n' > hello.sh
cat hello.sh
ls -l hello.sh
```

You'll see something like `-rw-r--r--`. Read it in blocks:

```
-   rw-   r--   r--
│   │     │     └── others: read only
│   │     └── group: read only
│   └── owner (you): read, write
└── type: - file, d directory, l link
```

Now try to run it:

```bash
./hello.sh            # "Permission denied": no x (execute) permission
chmod +x hello.sh     # add execute permission
ls -l hello.sh        # now -rwxr-xr-x
./hello.sh            # works
bash hello.sh         # also works, even without x: bash is reading the file, not executing it
```

The numeric form, which interviewers often ask about: **r=4, w=2, x=1**, added up for each block.

```bash
chmod 755 hello.sh    # rwx r-x r-x  (7=4+2+1, 5=4+1): typical for scripts
chmod 644 hello.sh    # rw- r-- r--: typical for data files
chmod 600 hello.sh    # rw- --- ---: private, e.g. a file holding credentials
ls -l hello.sh
chmod 755 hello.sh    # set it back
```

**Why `./hello.sh` and not just `hello.sh`?** The shell only looks for commands in the folders listed in the `PATH` variable, and your current folder isn't one of them. `./` means "this folder". Try `echo $PATH` to see the list.

The first line, `#!/usr/bin/env bash`, is the **shebang**. It tells the system which program should run the file. You'll write it at the top of every script from Day 4.

## 1.7 Closing drill (10 min, no notes)

Start from your home directory (`cd ~`) and do all of these from memory, using Tab completion:

1. Go into `~/bash-course/lab/data/curves`.
2. Print where you are.
3. List the files newest-first with readable sizes.
4. Count the September files.
5. Show the header plus the first two data rows of the 3 September file.
6. Count only the data rows in the 12 August file. (Is it 12?)
7. Create `~/bash-course/lab/scratch/review/` in one command, and copy the 12 August and 8 September files into it.
8. Find every `.log` file anywhere under `~/bash-course`.
9. Create a script in `~/bash-course/practice` that prints today's date (`date`), make it executable, and run it.
10. Delete the `scratch` folder entirely, after checking with `ls` that you have the right path.

<details><summary>Answer</summary>

```bash
cd ~/bash-course/lab/data/curves
pwd
ls -lht
ls sofr_ois_2026-09-*.csv | wc -l                        # 9
head -n 3 sofr_ois_2026-09-03.csv
tail -n +2 sofr_ois_2026-08-12.csv | wc -l               # 11, one tenor short
mkdir -p ~/bash-course/lab/scratch/review
cp sofr_ois_2026-08-12.csv sofr_ois_2026-09-08.csv ~/bash-course/lab/scratch/review/
find ~/bash-course -name '*.log'
printf '#!/usr/bin/env bash\ndate\n' > ~/bash-course/practice/today.sh
chmod +x ~/bash-course/practice/today.sh
~/bash-course/practice/today.sh
ls ~/bash-course/lab/scratch
rm -r ~/bash-course/lab/scratch
```
</details>

If you finished all ten in under 10 minutes without looking anything up, Day 1 is done.

## 1.8 Lab: Part A

Open `exercises.md` and complete **Part A, questions 1–4**. Question 2 needs `comm`, which you haven't met yet: read `man comm` or look ahead to section 2.6, and give it a try.

## Day 1 checklist

You should be able to answer these without looking anything up:

- [ ] What's the difference between an absolute and a relative path?
- [ ] What does `mkdir -p` do that `mkdir` doesn't?
- [ ] What's the difference between `rm file` and `rm -r folder`?
- [ ] How do you skip the first line of a file?
- [ ] What's the difference between `wc -l file` and `wc -l < file`?
- [ ] Why quote the pattern in `find -name '*.csv'`?
- [ ] What does `chmod 755` mean?
- [ ] Why `./script.sh` and not `script.sh`?
---

# Day 2: Filtering and Counting

**Goal:** search, slice, sort and count text data by chaining small commands with pipes. By the end of the day you can answer most "how many / which ones" questions about a dataset in one line.
**Time:** about 2 hours.
**Commands:** `|`, `grep`, `cut`, `sort`, `uniq`, `comm`, `tr`, `sed`

## Warm-up (5 min, from memory)

1. Go to `~/bash-course/lab/data/curves`.
2. Count the files.
3. Show the last 4 lines of the most recent file.
4. Find every `.txt` file under `~/bash-course/lab`.
5. Show the 3 September file with the header removed.

<details><summary>Answer</summary>

```bash
cd ~/bash-course/lab/data/curves
ls | wc -l
tail -n 4 sofr_ois_2026-09-11.csv
find ~/bash-course/lab -name '*.txt'
tail -n +2 sofr_ois_2026-09-03.csv
```
</details>

For the rest of the day, set two shortcuts so the commands stay short. Run these once at the start of each session:

```bash
cd ~/bash-course/lab
L=logs/feed_handler.log
F=data/curves/sofr_ois_2026-09-03.csv
echo $L $F
```

`L` and `F` are shell variables; `$L` is replaced by its value. You'll write variables properly on Day 4.

## 2.1 Pipes: the core idea (5 min)

Each Unix command does one small job. The pipe `|` connects them: the output of the left command becomes the input of the right one.

```bash
cat $L | wc -l              # how many lines in the log?
cat $L | head -3            # first 3 lines
cat $L | grep ERROR | wc -l # how many ERROR lines?
```

**Build pipelines one stage at a time.** Run the first command, look at the output, add the next stage, look again. Never write a five-stage pipeline in one go; when it breaks you won't know where.

(`cat file | cmd` works, but most commands can read the file directly: `grep ERROR $L | wc -l` is the same and slightly cleaner.)

## 2.2 `grep`: find lines that match (25 min)

```bash
grep ERROR $L                 # every line containing ERROR
grep -c ERROR $L              # count matching lines: 6
grep -n TIMEOUT $L            # show line numbers
grep -i timeout $L            # case-insensitive
grep -v INFO $L               # invert: lines NOT containing INFO
grep -v INFO $L | wc -l       # 10
grep -E 'WARN|ERROR' $L       # extended regex: WARN or ERROR
grep -c -E 'WARN|ERROR' $L    # 10, the same lines as grep -v INFO
```

Searching across files:

```bash
grep -H ',10Y,' data/curves/*.csv | head -3     # -H shows the filename on each match
grep -l ',BGN,' data/curves/*.csv               # -l lists only the files that contain a match
grep -c ',ON,' data/curves/*.csv | head -3      # count per file
```

Matching precisely:

```bash
grep 0Y $F            # matches 10Y, 20Y AND 30Y: grep matches anywhere in the line
grep -w 0Y $F         # -w: whole words only, so nothing matches here
grep ',10Y,' $F       # include the delimiters: the safest way to match one CSV value
grep '^2026-09-0[1-4]' $L | grep ERROR     # ^ = start of line
grep 'retry 2/3$' $L                       # $ = end of line
grep -F '4.3' $F      # -F: fixed string, so . means a literal dot, not "any character"
```

Regular expression basics you need for now:

| Pattern | Means |
|---|---|
| `.` | any single character |
| `*` | the previous thing, zero or more times |
| `^` / `$` | start / end of line |
| `[0-9]` | one digit |
| `a\|b` with `-E` | a or b |

### Practice 1

1. How many INFO lines are in the log?
2. Show every log line from 21 August, with line numbers.
3. Which curve files mention the source `BGN`?
4. Show all WARN lines, but not lines about retries.
5. Show every 30Y row across all files where the rate starts with `4.0`.

<details><summary>Answer</summary>

```bash
grep -c INFO $L                              # 90
grep -n '^2026-08-21' $L
grep -l ',BGN,' data/curves/*.csv
grep WARN $L | grep -v retry
grep -h ',30Y,4\.0' data/curves/*.csv        # -h hides filenames; \. is a literal dot
```
</details>

## 2.3 `cut`: pick columns (10 min)

```bash
cut -d, -f2 $F            # -d sets the delimiter (comma), -f picks field 2
cut -d, -f2,3 $F          # fields 2 and 3
cut -d, -f1-3 $F          # fields 1 to 3
cut -d' ' -f1,3 $L | head # the log is space-separated: date and level
```

`cut` treats every single delimiter as a field boundary. Two spaces in a row produce an empty field between them, so on messy whitespace `cut` can surprise you. That's one reason `awk` (Day 3) is often preferred.

## 2.4 `sort` (15 min)

```bash
tail -n +2 $F | sort -t, -k3,3n          # sort by field 3, numerically
tail -n +2 $F | sort -t, -k3,3nr         # numerically, highest first
tail -n +2 $F | sort -t, -k3,3nr | head -1    # the highest rate on the curve
tail -n +2 $F | sort -t, -k2,2           # by tenor, alphabetically
```

- `-t,` sets the delimiter.
- `-k3,3` means "use field 3 only". Plain `-k3` means "from field 3 to the end of the line", a very common mistake.
- `n` means numeric, `r` means reverse.

See why numeric sort matters:

```bash
printf '3\n10\n2\n' | sort       # 10, 2, 3: text sort compares character by character
printf '3\n10\n2\n' | sort -n    # 2, 3, 10
```

Sort by more than one key, which you'll need for time series:

```bash
tail -q -n +2 data/curves/*.csv | sort -t, -k2,2 -k1,1 | head -15
```

This combines every file without headers (`tail -q` suppresses the filename banners), then sorts by tenor and, within each tenor, by date. Now each tenor's history sits together in date order. Remember this one; it comes back on Day 3.

Other useful options: `sort -u` (sort and remove duplicates), `sort -h` (human sizes like 2K, 1M).

## 2.5 `uniq`: collapse and count repeats (15 min)

`uniq` only removes **adjacent** duplicates, so you almost always `sort` first.

```bash
cut -d, -f4 $F | uniq                            # BBG once per run of BBGs
tail -q -n +2 data/curves/*.csv | cut -d, -f4 | sort | uniq -c     # count per source
tail -q -n +2 data/curves/*.csv | cut -d, -f2 | sort | uniq -c     # rows per tenor
```

The second line is the single most useful idiom in this guide. **`cut | sort | uniq -c`** builds a frequency table of any column. Add `| sort -rn` to rank it:

```bash
cut -d' ' -f3 $L | sort | uniq -c | sort -rn     # log levels, most common first
```

`uniq -d` shows only values that appear more than once; `uniq -u` shows only those that appear exactly once.

### Practice 2

1. How many rows does each tenor have across all files? Do all tenors have the same count?
2. List the distinct tenors on one line, separated by spaces. (Hint: `sort -u`, then section 2.7.)
3. Which dates appear in the log? Count them.
4. Rank the 3 September curve from lowest to highest rate, showing only tenor and rate.

<details><summary>Answer</summary>

```bash
tail -q -n +2 data/curves/*.csv | cut -d, -f2 | sort | uniq -c
# No: one tenor has fewer rows and one has more. The lab will make you explain why.
tail -q -n +2 data/curves/*.csv | cut -d, -f2 | sort -u | tr '\n' ' '; echo
cut -d' ' -f1 $L | sort -u | wc -l           # 30
tail -n +2 $F | sort -t, -k3,3n | cut -d, -f2,3
```
</details>

## 2.6 `comm`: compare two lists (10 min)

`comm` compares two **sorted** lists and shows three columns: only in the first, only in the second, in both.

```bash
printf 'a\nb\nc\n' > /tmp/x.txt
printf 'b\nc\nd\n' > /tmp/y.txt
comm /tmp/x.txt /tmp/y.txt       # three columns
comm -23 /tmp/x.txt /tmp/y.txt   # suppress columns 2 and 3: only in x → a
comm -13 /tmp/x.txt /tmp/y.txt   # only in y → d
comm -12 /tmp/x.txt /tmp/y.txt   # in both → b, c
```

Both inputs must be sorted the same way. If not, `comm` gives wrong answers, often without any error. `ref/tenors.txt` is in curve order (ON, 1M, 3M…), which is *not* sorted, so it needs `sort` before use:

```bash
comm -12 <(sort ref/tenors.txt) <(tail -n +2 $F | cut -d, -f2 | sort)
```

`<( ... )` is **process substitution**: it lets a command's output be used where a filename is expected. You'll use it with `comm` and `diff` all the time.

## 2.7 `tr`: translate characters (5 min)

```bash
head -2 $F | tr ',' '\t'        # commas to tabs
head -2 $F | tr 'a-z' 'A-Z'     # to upper case
cut -d, -f2 $F | tr '\n' ' '    # join lines with spaces
echo "a,,b" | tr -s ','         # -s squeezes repeats: a,b
echo "4.31%" | tr -d '%'        # -d deletes characters: 4.31
```

## 2.8 `sed`: edit text on the fly (15 min)

`sed` (stream editor) changes text as it passes through. The original file is untouched unless you use `-i`.

```bash
sed 's/BBG/Bloomberg/' $F | head -3        # s/old/new/: replace the first match on each line
sed 's/,/ | /g' $F | head -3               # g: replace every match on the line
sed -n '2,4p' $F                           # -n + p: print only lines 2 to 4
sed '1d' $F | head -2                      # delete line 1 (another way to drop a header)
sed '/^2026-09-03,ON/d' $F | head -2       # delete lines matching a pattern
sed -E 's/sofr_ois_(.*)\.csv/\1/' <<< "sofr_ois_2026-09-03.csv"   # capture group: 2026-09-03
```

The last one is important. `-E` enables extended regex, `( )` captures part of the match, and `\1` puts the captured part back. Here it extracts the date from a filename. (`<<<` feeds a string as input; more on Day 4.)

Turn every filename into a date:

```bash
ls data/curves | sed -E 's/sofr_ois_(.*)\.csv/\1/' | head -3
```

Editing a file in place:

```bash
cp $F /tmp/test.csv
sed -i 's/BBG/Bloomberg/g' /tmp/test.csv     # macOS: sed -i '' 's/BBG/Bloomberg/g' /tmp/test.csv
head -3 /tmp/test.csv
```

> `sed -i` overwrites the file with no undo. Test the expression without `-i` first, and keep a copy.

## 2.9 Closing drill (15 min, no notes)

From `~/bash-course/lab`:

1. Count the log lines that are not INFO.
2. List the distinct WARN messages in the log (the text after `feed_handler:`), with a count of each.
3. Show the five lowest rates across *all* curve files, with date and tenor.
4. List every date that has a file, as plain dates, one per line.
5. Using `comm`, check whether every tenor in `ref/tenors.txt` appears in the 3 September file. (No output from `comm -23` means none are missing.)
6. Show the 10Y history (date and rate only) in date order.

<details><summary>Answer</summary>

```bash
grep -vc INFO $L                                                   # 10
grep WARN $L | sed 's/.*feed_handler: //' | sort | uniq -c
tail -q -n +2 data/curves/*.csv | sort -t, -k3,3n | head -5 | cut -d, -f1-3
ls data/curves | sed -E 's/sofr_ois_(.*)\.csv/\1/'
comm -23 <(sort ref/tenors.txt) <(tail -n +2 $F | cut -d, -f2 | sort)
grep -h ',10Y,' data/curves/*.csv | cut -d, -f1,3
```

Question 3 turns up two surprises. The first row has no rate at all: a blank sorts before every number. The second is a rate far below every other value. Neither is a market move; both are data problems, and both are lab findings.
</details>

## 2.10 Lab: Part B

Complete **Part B, questions 5–10** in `exercises.md`. You now have every tool you need.

## Day 2 checklist

- [ ] Why build pipelines one stage at a time?
- [ ] What do `grep -v`, `-c`, `-l`, `-w` and `-E` do?
- [ ] Why does `uniq` usually need `sort` first?
- [ ] What's the difference between `sort -k2` and `sort -k2,2`?
- [ ] Why does `sort` put 10 before 2, and how do you fix it?
- [ ] What must be true of both inputs to `comm`?
- [ ] What does `<( ... )` do?
- [ ] How do you extract part of a string with `sed`?
- [ ] Write the frequency-table idiom from memory.
---

# Day 3: awk

**Goal:** use `awk` to filter by conditions, calculate, aggregate by group, and compare each row with the previous one. This is the day bash becomes a genuine data-analysis tool, so it's worth the most time.
**Time:** about 2 hours.
**Commands:** `awk` (fields, `-F`, `NR`, `FNR`, `NF`, `FILENAME`, conditions, `printf`, variables, `BEGIN`/`END`, arrays, `-v`)

## Warm-up (5 min, from memory)

From `~/bash-course/lab`:

1. Count the WARN lines in the log.
2. Show tenor and rate for the 3 September file, without the header.
3. Count rows per source across all curve files.
4. Sort the 3 September file by rate, highest first.
5. Extract the date from the filename `sofr_ois_2026-09-03.csv` using `sed`.

<details><summary>Answer</summary>

```bash
grep -c WARN logs/feed_handler.log
tail -n +2 data/curves/sofr_ois_2026-09-03.csv | cut -d, -f2,3
tail -q -n +2 data/curves/*.csv | cut -d, -f4 | sort | uniq -c
tail -n +2 data/curves/sofr_ois_2026-09-03.csv | sort -t, -k3,3nr
sed -E 's/sofr_ois_(.*)\.csv/\1/' <<< "sofr_ois_2026-09-03.csv"
```
</details>

Set the shortcuts again:

```bash
cd ~/bash-course/lab
L=logs/feed_handler.log
F=data/curves/sofr_ois_2026-09-03.csv
C=data/curves
```

## 3.1 How awk thinks (10 min)

An awk program is a list of **`pattern { action }`** rules. awk reads the input one line at a time, splits it into fields, and for each line runs the action wherever the pattern is true.

```bash
awk '{ print }' $F                  # no pattern: run on every line → prints the file
awk 'NR > 1' $F                     # no action: default action is print → skip the header
awk 'NR > 1 { print $2 }' $F        # pattern and action
```

Fields are `$1`, `$2`, `$3`…; `$0` is the whole line. By default fields are split on whitespace. For CSV, set the separator with `-F,`:

```bash
awk '{ print $2 }' $F         # wrong: no spaces in the line, so $2 is empty
awk -F, '{ print $2 }' $F     # right: field 2 is the tenor
awk -F, '{ print $2, $3 }' $F # a comma in print means "output separated by a space"
awk -F, '{ print $2 ": " $3 "%" }' $F    # strings next to each other are joined
```

Always put the awk program in **single quotes**, so the shell doesn't touch the `$` signs.

## 3.2 Built-in variables (10 min)

| Variable | Meaning |
|---|---|
| `NR` | line number across all input |
| `FNR` | line number within the current file |
| `NF` | number of fields on this line |
| `$NF` | the last field |
| `FILENAME` | the current file's name |

```bash
awk -F, '{ print NR, NF }' $F | head -3
awk -F, '{ print $NF }' $F | head -3           # last field: snapshot time
awk -F, 'FNR == 1 { print FILENAME }' $C/sofr_ois_2026-09-0*.csv
```

**`NR` versus `FNR` matters as soon as you have more than one file:**

```bash
awk -F, 'NR > 1' $C/sofr_ois_2026-09-0[12].csv | grep -c date    # 1: the second header slipped through
awk -F, 'FNR > 1' $C/sofr_ois_2026-09-0[12].csv | grep -c date   # 0: every header skipped
```

## 3.3 Conditions (15 min)

```bash
awk -F, 'NR > 1 && $3 > 4 { print $2, $3 }' $F        # rates above 4%
awk -F, '$2 == "10Y"' $C/*.csv | head -3               # one tenor across all files
awk -F, '$2 == "ON" || $2 == "30Y"' $F                 # || means or
awk -F, '$2 != "ON" && NR > 1' $F | head -3            # != means not equal
awk -F, '$2 ~ /Y$/' $F                                 # ~ means "matches regex": tenors ending in Y
awk -F, 'FNR > 1 && $4 != "BBG"' $C/*.csv              # rows not from Bloomberg
```

Look at the output of the first command. Rates above 4% should be the short end (ON, 1M, 3M, 6M) and the long end (20Y, 30Y). One tenor in the middle is also there. Keep that in mind for the lab.

Two traps:

- **Headers compare as text.** Without `NR > 1`, awk compares the word `rate_pct` with 4 as a string, and the header may sneak through.
- **A blank field counts as 0** in arithmetic and numeric comparisons. Guard with `$3 != ""` whenever a value might be missing.

## 3.4 Arithmetic and `printf` (10 min)

```bash
awk -F, 'NR > 1 { print $2, $3 * 100 }' $F                 # percent → basis points
awk -F, 'NR > 1 { printf "%-4s %7.3f%%  %6.1fbp\n", $2, $3, $3 * 100 }' $F
```

`printf` gives control over layout. It doesn't add a newline, so end with `\n`.

| Format | Meaning |
|---|---|
| `%s` | string |
| `%-4s` | string, left-aligned in 4 characters |
| `%d` | integer |
| `%.2f` | number with 2 decimals |
| `%7.3f` | 3 decimals, padded to 7 characters wide |
| `%+.1f` | always show the sign |
| `%%` | a literal % |

## 3.5 Accumulating: `BEGIN`, `END`, sums, min and max (20 min)

`BEGIN { }` runs before the first line; `END { }` runs after the last. Variables start empty (0 in arithmetic), and keep their values from line to line.

```bash
awk 'BEGIN { print "start" } END { print NR " lines" }' $F
awk -F, 'NR > 1 { s += $3; n++ } END { printf "average %.4f over %d rows\n", s/n, n }' $F
```

Minimum and maximum, with the tenor:

```bash
awk -F, 'NR > 1 && (max == "" || $3 > max) { max = $3; t = $2 }
         END { print "highest:", t, max }' $F

awk -F, 'NR > 1 && (min == "" || $3 < min) { min = $3; t = $2 }
         END { print "lowest:", t, min }' $F
```

`max == ""` is true only on the first data row, so the first value always becomes the starting point. Starting `max` at 0 instead would break on negative numbers, a real issue for EUR and JPY rates in recent years.

Programs can run across several lines inside the quotes, as above. Use that whenever a one-liner gets hard to read.

### Practice 1

1. Print every 3 September tenor whose rate is between 3.7% and 3.8%.
2. Count how many rows across all files have a rate above 4.2%.
3. Find the average 30Y rate across all files.
4. Find the highest ON rate across all files and the date it occurred.

<details><summary>Answer</summary>

```bash
awk -F, 'NR > 1 && $3 >= 3.7 && $3 <= 3.8 { print $2, $3 }' $F
awk -F, 'FNR > 1 && $3 > 4.2' $C/*.csv | wc -l
awk -F, '$2 == "30Y" { s += $3; n++ } END { printf "%.4f\n", s/n }' $C/*.csv
awk -F, '$2 == "ON" && (max == "" || $3 > max) { max = $3; d = $1 } END { print d, max }' $C/*.csv
```
</details>

## 3.6 Arrays: group-by in one line (25 min)

awk arrays are **associative**: indexed by any string, like a dictionary. They're how you do the equivalent of SQL `GROUP BY`.

Count rows per source:

```bash
awk -F, 'FNR > 1 { n[$4]++ } END { for (s in n) print s, n[s] }' $C/*.csv
```

Average rate per tenor, skipping blanks:

```bash
awk -F, 'FNR > 1 && $3 != "" { s[$2] += $3; n[$2]++ }
         END { for (t in s) printf "%-4s %.4f\n", t, s[t]/n[t] }' $C/*.csv
```

`for (k in array)` visits keys in **no particular order**. Pipe to `sort` when order matters.

Errors per day in the log (the log is space-separated, so no `-F` is needed):

```bash
awk '$3 == "ERROR" { c[$1]++ } END { for (d in c) print d, c[d] }' $L | sort
```

**Pivoting with two-part keys.** `r[$1, $2]` stores a value under the pair (date, tenor). Here's the 2s10s curve slope (10Y minus 2Y, in basis points) for every date:

```bash
awk -F, 'FNR > 1 { r[$1, $2] = $3; d[$1] = 1 }
         END { for (x in d) if (r[x, "10Y"] != "" && r[x, "2Y"] != "")
                 printf "%s %.1f\n", x, (r[x, "10Y"] - r[x, "2Y"]) * 100 }' $C/*.csv | sort
```

Sort it by slope to see the extremes:

```bash
awk -F, 'FNR > 1 { r[$1, $2] = $3; d[$1] = 1 }
         END { for (x in d) if (r[x, "10Y"] != "" && r[x, "2Y"] != "")
                 printf "%s %.1f\n", x, (r[x, "10Y"] - r[x, "2Y"]) * 100 }' $C/*.csv | sort -k2,2n | sed -n '1p;$p'
```

The slope is normally around 8–12bp, but one day is over 50bp. A slope can't really jump like that and come back; something is wrong with one of its inputs that day.

### Practice 2

1. Find the minimum and maximum rate for each tenor.
2. For each date, count how many tenors it has. Print only dates with a count other than 12.
3. For each date, compute the 5s30s slope (30Y minus 5Y) in basis points.

<details><summary>Answer</summary>

```bash
awk -F, 'FNR > 1 && $3 != "" {
           if (!($2 in lo) || $3 < lo[$2]) lo[$2] = $3
           if (!($2 in hi) || $3 > hi[$2]) hi[$2] = $3 }
         END { for (t in lo) print t, lo[t], hi[t] }' $C/*.csv | sort

awk -F, 'FNR > 1 { n[$1]++ } END { for (d in n) if (n[d] != 12) print d, n[d] }' $C/*.csv

awk -F, 'FNR > 1 { r[$1, $2] = $3; d[$1] = 1 }
         END { for (x in d) printf "%s %.1f\n", x, (r[x, "30Y"] - r[x, "5Y"]) * 100 }' $C/*.csv | sort
```

`($2 in lo)` tests whether a key exists, which avoids the "blank equals 0" trap.
</details>

## 3.7 Remembering the previous row (15 min)

Because variables persist between lines, you can compare each row with the one before. Store what you need at the *end* of the action, so it's still there when the next line arrives.

Differences between neighbouring tenors on one curve:

```bash
awk -F, 'NR > 1 { if (NR > 2) printf "%s-%s %+.1fbp\n", pt, $2, ($3 - pv) * 100
                  pt = $2; pv = $3 }' $F
```

Day-on-day change for one tenor across all files, in date order (filenames sort by date, so `$C/*.csv` arrives in date order):

```bash
awk -F, 'FNR > 1 && $2 == "10Y" && $3 != "" {
           if (p != "") printf "%s %+.1fbp\n", $1, ($3 - p) * 100
           p = $3 }' $C/*.csv
```

**Passing a shell value into awk with `-v`**, so the same program works for any tenor:

```bash
awk -F, -v t=5Y 'FNR > 1 && $2 == t { print $1, $3 }' $C/*.csv | head -3
TENOR=30Y
awk -F, -v t="$TENOR" 'FNR > 1 && $2 == t { print $1, $3 }' $C/*.csv | head -3
```

Use `-v` rather than trying to put `$TENOR` inside the single quotes, which won't work.

### Practice 3

1. Using `-v`, print the day-on-day changes for any tenor you choose, and try several.
2. For the 10Y, print only changes larger than 10bp in either direction.
3. Look at the result of question 2. What do you notice about the two dates?

<details><summary>Answer</summary>

```bash
awk -F, -v t=2Y 'FNR > 1 && $2 == t && $3 != "" {
           if (p != "") printf "%s %+.1fbp\n", $1, ($3 - p) * 100
           p = $3 }' $C/*.csv

awk -F, 'FNR > 1 && $2 == "10Y" && $3 != "" {
           if (p != "") { c = ($3 - p) * 100; if (c > 10 || c < -10) printf "%s %+.1fbp\n", $1, c }
           p = $3 }' $C/*.csv
```

The 10Y jumps by about 46bp one day and falls by almost exactly the same amount the next. Real markets rarely do that; it is the signature of a single bad data point. The lab asks you to find this pattern across every tenor at once.
</details>

## 3.8 Closing drill (10 min, no notes)

1. Print tenor and rate in basis points for the 3 September curve, formatted in neat columns.
2. Count log lines per level (INFO, WARN, ERROR) using awk alone, no `sort` or `uniq`.
3. Average rate per source across all files.
4. The number of rows in each file, using `FILENAME` and an array. Print only files without exactly 12 data rows.
5. Using `-v`, write a one-liner that prints a chosen date's curve, given a date like `2026-09-08`.

<details><summary>Answer</summary>

```bash
awk -F, 'NR > 1 { printf "%-4s %8.1f\n", $2, $3 * 100 }' $F
awk '{ c[$3]++ } END { for (k in c) print k, c[k] }' $L
awk -F, 'FNR > 1 && $3 != "" { s[$4] += $3; n[$4]++ } END { for (k in s) printf "%s %.4f\n", k, s[k]/n[k] }' $C/*.csv
awk -F, 'FNR > 1 { n[FILENAME]++ } END { for (f in n) if (n[f] != 12) print f, n[f] }' $C/*.csv
awk -F, -v d=2026-09-08 '$1 == d { print $2, $3, $4 }' $C/*.csv
```
</details>

## 3.9 Lab: Part C

Complete **Part C, questions 11–14** in `exercises.md`. Question 12 combines today with the multi-key `sort` from section 2.4; question 14 needs one more idea: count how many consecutive rows have the *same* value as the previous row.

## Day 3 checklist

- [ ] What is the structure of an awk program?
- [ ] Why must awk programs be in single quotes?
- [ ] What's the difference between `NR` and `FNR`?
- [ ] What happens to a blank field in arithmetic, and how do you guard against it?
- [ ] What do `BEGIN` and `END` do?
- [ ] How do you do a group-by in awk?
- [ ] Why pipe `for (k in arr)` output to `sort`?
- [ ] How do you compare a row with the previous row?
- [ ] How do you pass a shell variable into awk?
---

# Day 4: Scripting

**Goal:** turn one-liners into reliable, reusable scripts with arguments, conditions, loops, functions, proper error handling and meaningful exit codes. By the end you'll have written a script that summarises any day's curve, and you'll be ready to write the full data-health check.
**Time:** about 2 hours.
**Topics:** shebang, variables and quoting, arguments, defaults, arithmetic, `if` and tests, exit codes, `&&` and `||`, loops, redirection, functions, `xargs`, `set -euo pipefail`, debugging

## Warm-up (5 min, from memory)

From `~/bash-course/lab`:

1. Print tenor and rate for the 8 September curve using awk.
2. Find the average 2Y rate across all files.
3. Count rows per tenor across all files using an awk array.
4. Print the 3 September curve in basis points, with neat columns.

<details><summary>Answer</summary>

```bash
awk -F, 'NR > 1 { print $2, $3 }' data/curves/sofr_ois_2026-09-08.csv
awk -F, '$2 == "2Y" { s += $3; n++ } END { print s/n }' data/curves/*.csv
awk -F, 'FNR > 1 { n[$2]++ } END { for (t in n) print t, n[t] }' data/curves/*.csv | sort
awk -F, 'NR > 1 { printf "%-4s %8.1f\n", $2, $3 * 100 }' data/curves/sofr_ois_2026-09-03.csv
```
</details>

All of today's scripts go in `~/bash-course/practice`:

```bash
cd ~/bash-course/practice
```

To create or edit a script, use VS Code: `code myscript.sh` opens it in the editor. (On macOS, if `code` isn't found, open the Command Palette with Cmd+Shift+P and run "Shell Command: Install 'code' command in PATH".) Or use `nano myscript.sh` in the terminal: Ctrl+O saves, Ctrl+X exits.

## 4.1 Anatomy of a script (10 min)

Create `first.sh`:

```bash
#!/usr/bin/env bash
# My first script: comments start with #

echo "Running in: $(pwd)"
echo "Files in the lab curves folder: $(ls ../lab/data/curves | wc -l)"
```

Run it:

```bash
chmod +x first.sh
./first.sh
```

- Line 1, the **shebang**, says "run this with bash".
- `$( command )` is **command substitution**: it runs the command and inserts its output. It's how you capture results into text or variables.

## 4.2 Variables and quoting (15 min)

Create `vars.sh`:

```bash
#!/usr/bin/env bash
name="Sijie"
tenor="10Y"
count=$(ls ../lab/data/curves | wc -l)

echo "Hello $name"
echo 'Hello $name'
echo "File: ${tenor}_history.csv"
echo "File: $tenor_history.csv"
echo "There are $count files"
```

Run it and look carefully at each line of output:

- **No spaces around `=`.** `name = "Sijie"` is an error: bash thinks `name` is a command.
- **Double quotes** expand `$variables` and `$(commands)`. **Single quotes** keep everything literal.
- **`${tenor}_history`**: braces mark where the variable name ends. Without them, bash looks for a variable called `tenor_history`, which doesn't exist, so it prints nothing there.

**Always quote variables: `"$file"`, not `$file`.** See why:

```bash
touch "my report.csv"
f="my report.csv"
ls -l $f          # fails: bash splits it into two arguments, "my" and "report.csv"
ls -l "$f"        # works
rm "my report.csv"
```

Real filenames contain spaces. Unquoted variables are the most common source of bash bugs.

## 4.3 Arguments and defaults (15 min)

Create `args.sh`:

```bash
#!/usr/bin/env bash
echo "Script name:     $0"
echo "First argument:  $1"
echo "Second argument: $2"
echo "Number of args:  $#"
echo "All arguments:   $*"

tenor="${1:-10Y}"
echo "Tenor to use:    $tenor"
```

```bash
chmod +x args.sh
./args.sh 5Y 2026-09-03
./args.sh
./args.sh "two words" x
```

Parameter expansion patterns you'll use constantly:

| Pattern | Meaning |
|---|---|
| `${1:-10Y}` | use `$1`; if empty or missing, use `10Y` |
| `${1:?usage: $0 TENOR}` | use `$1`; if missing, print the message and exit with an error |
| `${DATA_DIR:-../lab/data/curves}` | use the environment variable if set, otherwise this default |

The last one lets the same script run against test or production data without editing it:

```bash
DATA_DIR=/some/other/path ./myscript.sh     # sets DATA_DIR for this one command only
```

To loop over every argument safely, use `"$@"` (quoted). It keeps each argument intact, even ones containing spaces.

## 4.4 Arithmetic (5 min)

Bash integer arithmetic uses `$(( ))`:

```bash
x=7; y=3
echo $(( x + y )) $(( x * y )) $(( x / y )) $(( x % y ))   # 10 21 2 1: integer division
count=0
count=$(( count + 1 ))
(( count++ ))
echo $count                                                 # 2
```

Bash only does integers: `$(( 3.5 + 1 ))` is an error. For decimals, use awk: `awk 'BEGIN { print 3.5 + 1 }'`.

One trap for later: under `set -e` (section 4.11), `(( count++ ))` when `count` is 0 counts as a failure and stops the script, because the expression's value is 0. Prefer `count=$(( count + 1 ))` in scripts.

## 4.5 Conditions with `if` (15 min)

Create `rowcheck.sh`:

```bash
#!/usr/bin/env bash
file="${1:?usage: $0 FILE}"

if [[ -f "$file" ]]; then
  echo "$file exists"
  rows=$(tail -n +2 "$file" | wc -l)
  if (( rows == 12 )); then
    echo "row count OK"
  elif (( rows < 12 )); then
    echo "too few rows: $rows"
  else
    echo "too many rows: $rows"
  fi
else
  echo "no such file: $file"
fi
```

Run it on a healthy file, the 12 August file, the 8 September file, and a file that doesn't exist:

```bash
chmod +x rowcheck.sh
./rowcheck.sh ../lab/data/curves/sofr_ois_2026-09-03.csv
./rowcheck.sh ../lab/data/curves/sofr_ois_2026-08-12.csv
./rowcheck.sh ../lab/data/curves/sofr_ois_2026-09-08.csv
./rowcheck.sh ../lab/data/curves/sofr_ois_2026-08-21.csv
```

Common tests inside `[[ ]]`:

| Test | True when |
|---|---|
| `-f "$x"` / `-d "$x"` | file / directory exists |
| `-z "$x"` / `-n "$x"` | string is empty / not empty |
| `"$a" == "$b"` / `!=` | strings equal / not equal |
| `! -f "$x"` | `!` negates any test |
| `"$a" == 2026-09*` | pattern match (no quotes on the right side) |

For numbers use `(( ))`: `(( rows == 12 ))`, `(( n > 0 ))`. The older form `[ "$n" -eq 12 ]` also works, and you'll see it in older scripts.

Spaces matter: `[[ -f "$file" ]]` needs a space after `[[` and before `]]`.

## 4.6 Exit codes, `&&` and `||` (10 min)

Every command finishes with an **exit code**: 0 means success, anything else means failure. `$?` holds the last one.

```bash
ls ~/bash-course; echo "exit code: $?"                    # 0
ls /nonexistent; echo "exit code: $?"                     # non-zero
grep -q TIMEOUT ../lab/logs/feed_handler.log; echo $?     # 0: found (-q = quiet, no output)
grep -q NOTHING ../lab/logs/feed_handler.log; echo $?     # 1: not found
```

Chaining on success or failure:

```bash
mkdir -p /tmp/demo && echo "created"                  # && : run only if the first succeeded
ls /nonexistent || echo "that failed"                 # || : run only if the first failed
grep -q TIMEOUT ../lab/logs/feed_handler.log && echo "feed had timeouts"
```

`if` tests an exit code directly, which is cleaner than checking `$?`:

```bash
if grep -q TIMEOUT ../lab/logs/feed_handler.log; then echo "timeouts found"; fi
```

Your own scripts should finish with `exit 0` on success and `exit 1` (or another non-zero code) on failure. Cron, Airflow and CI systems all decide what to do next based on that code. That's why the lab's health check must exit 1 when it finds problems.

## 4.7 Loops (15 min)

Over files:

```bash
for f in ../lab/data/curves/sofr_ois_2026-09-0*.csv; do
  echo "$(basename "$f") $(tail -n +2 "$f" | wc -l)"
done
```

`basename` strips the folder from a path (`dirname` does the opposite).

Over a list or a range:

```bash
for t in ON 2Y 10Y 30Y; do echo "tenor $t"; done
for i in {1..5}; do echo "run $i"; done
```

Reading a file line by line, the safe way:

```bash
while read -r d; do
  f="../lab/data/curves/sofr_ois_${d}.csv"
  [[ -f "$f" ]] || echo "missing: $d"
done < ../lab/ref/business_days.txt
```

`-r` stops backslashes being treated as escapes. `done < file` feeds the file into the whole loop.

`continue` skips to the next iteration; `break` leaves the loop.

> Avoid `for line in $(cat file)`. It splits on spaces as well as newlines, so any line containing a space breaks into pieces. Use `while read -r` instead.

## 4.8 Redirection (10 min)

| Syntax | Meaning |
|---|---|
| `cmd > file` | send output to a file (overwrite) |
| `cmd >> file` | append |
| `cmd 2> file` | send **errors** (stderr) to a file |
| `cmd > file 2>&1` | send both output and errors to the file |
| `cmd > /dev/null` | discard output |
| `echo "msg" >&2` | write a message to stderr |
| `cmd < file` | read input from a file |
| `cmd <<< "text"` | feed a string as input |

Try them:

```bash
ls ~/bash-course /nonexistent                      # output and an error, both on screen
ls ~/bash-course /nonexistent > out.txt            # the error still shows; output went to the file
ls ~/bash-course /nonexistent > out.txt 2>&1       # both into the file
cat out.txt
ls ~/bash-course /nonexistent > /dev/null 2>&1; echo "silent, exit $?"
```

**Order matters:** `> file 2>&1` sends both to the file. `2>&1 > file` points stderr at wherever stdout pointed *before* the redirect, which is still the screen.

Scripts should print error messages to stderr (`>&2`), so they don't get mixed into data output that might be piped into another command.

A **here-document** writes a multi-line block. Everything between the first line and the closing word goes into the file:

```bash
cat > note.txt << 'END'
Daily check completed.
No issues found.
END
cat note.txt
```

## 4.9 Functions (5 min)

Create `funcs.sh`:

```bash
#!/usr/bin/env bash
log() { echo "$(date '+%H:%M:%S') $*"; }

file_rows() {
  local f="$1"
  tail -n +2 "$f" | wc -l
}

log "starting"
log "rows on 3 Sep: $(file_rows ../lab/data/curves/sofr_ois_2026-09-03.csv)"
```

Inside a function, `$1`, `$2` are the function's own arguments. `local` keeps a variable inside the function. A function "returns" a value by printing it, which you capture with `$( )`.

## 4.10 `xargs` (5 min)

`xargs` turns lines of input into arguments for a command:

```bash
ls ../lab/data/curves/*09-0[1-3]*.csv | xargs wc -l
find ../lab -name '*.csv' | xargs grep -l BGN
ls ../lab/data/curves/*.csv | tail -5 | xargs awk -F, 'FNR > 1 && $2 == "10Y" { print $1, $3 }'
```

The last line is a useful pattern: "run awk over only the five most recent files."

## 4.11 Safety and debugging: `set -euo pipefail` (10 min)

By default bash carries on after errors, which is dangerous in a production script. Start every serious script with:

```bash
set -euo pipefail
```

See what each part does:

```bash
bash -c 'false; echo "still running"'                    # default: keeps going
bash -c 'set -e; false; echo "never printed"'; echo "exit: $?"

bash -c 'echo "value: $typo"'                            # default: silently empty
bash -c 'set -u; echo "value: $typo"'; echo "exit: $?"   # -u: error on undefined variables

bash -c 'false | true; echo "exit: $?"'                  # 0: only the LAST command counts
bash -c 'set -o pipefail; false | true; echo "exit: $?"' # 1: any failing stage fails the pipe
```

One consequence: under `set -e`, a command that "fails" as a normal outcome, like `grep` finding nothing, stops the script. When that's acceptable, add `|| true`:

```bash
matches=$(grep TIMEOUT "$log" || true)
```

**Debugging:** run a script with `bash -x script.sh` to print each command before it runs, with variables already filled in. It's the fastest way to see where a script goes wrong.

## 4.12 Build it: `daily_summary.sh` (25 min)

Now combine everything. Build this script in stages, running it after each one.

**Stage 1: take a date and find the file.**

```bash
#!/usr/bin/env bash
set -euo pipefail

DATE="${1:?usage: $0 YYYY-MM-DD}"
DIR="${DATA_DIR:-../lab/data/curves}"
FILE="$DIR/sofr_ois_${DATE}.csv"

echo "Looking for $FILE"
```

```bash
chmod +x daily_summary.sh
./daily_summary.sh 2026-09-03
./daily_summary.sh               # should print the usage message
```

**Stage 2: fail cleanly if the file is missing.** Add:

```bash
if [[ ! -f "$FILE" ]]; then
  echo "No file for $DATE" >&2
  exit 1
fi
```

Test with `./daily_summary.sh 2026-08-21; echo "exit: $?"`. You should see the message and exit code 1.

**Stage 3: the summary.** Delete the `echo "Looking for..."` line and add at the end:

```bash
rows=$(tail -n +2 "$FILE" | wc -l)

read -r lo_t lo hi_t hi < <(awk -F, 'NR > 1 && $3 != "" {
    if (lo == "" || $3 < lo) { lo = $3; lt = $2 }
    if (hi == "" || $3 > hi) { hi = $3; ht = $2 } }
    END { print lt, lo, ht, hi }' "$FILE")

slope=$(awk -F, 'NR > 1 { r[$2] = $3 } END { printf "%.1f", (r["10Y"] - r["2Y"]) * 100 }' "$FILE")

echo "Date:   $DATE"
echo "Rows:   $rows"
echo "Low:    $lo_t $lo%"
echo "High:   $hi_t $hi%"
echo "2s10s:  ${slope}bp"
```

`read -r a b c d < <(command)` splits one line of output into four variables.

Expected result for 3 September:

```
Date:   2026-09-03
Rows:   12
Low:    5Y 3.6285%
High:   ON 4.3753%
2s10s:  53.5bp
```

(That 53.5bp slope is suspicious. Compare it with a few other days.)

**Stage 4: your own improvements.** Add each of these yourself:

1. A warning to stderr when `rows` isn't 12, and exit code 1 at the end if so.
2. A `--quiet` mode: if the second argument is `--quiet`, print nothing and rely only on the exit code.
3. A new script, `all_summaries.sh`, that runs `daily_summary.sh` for every date in `ref/business_days.txt` and prints just `DATE  2s10s` per line, skipping missing dates without stopping.

<details><summary>Answer (Stage 4)</summary>

In `daily_summary.sh`, after computing `rows`:

```bash
status=0
if (( rows != 12 )); then
  echo "WARNING: $DATE has $rows rows, expected 12" >&2
  status=1
fi
```

For quiet mode, near the top:

```bash
QUIET="${2:-}"
```

and wrap the `echo` lines, then exit with the status:

```bash
if [[ "$QUIET" != "--quiet" ]]; then
  echo "Date:   $DATE"
  echo "Rows:   $rows"
  echo "Low:    $lo_t $lo%"
  echo "High:   $hi_t $hi%"
  echo "2s10s:  ${slope}bp"
fi
exit "$status"
```

`all_summaries.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
while read -r d; do
  out=$(./daily_summary.sh "$d" 2>/dev/null) || true
  [[ -z "$out" ]] && continue
  echo "$d  $(grep 2s10s <<< "$out" | awk '{ print $2 }')"
done < ../lab/ref/business_days.txt
```

The `|| true` stops `set -e` killing the loop when a day returns exit code 1.
</details>

## 4.13 Lab: Part D

Complete **Part D, questions 15–16** in `exercises.md`. Question 15 is the main event of the course: a full data-health check script. Use `daily_summary.sh` as a template, and turn each check from Parts B and C into a block that prints a `FAIL` line.

Take your time over it. A clean, well-structured version of this script is something you can talk through in an interview as evidence of production-minded thinking.

## Day 4 checklist

- [ ] Why no spaces around `=`?
- [ ] What's the difference between single and double quotes?
- [ ] Why always write `"$var"` rather than `$var`?
- [ ] What do `$1`, `$#`, `"$@"` and `$?` mean?
- [ ] What does `${1:-default}` do? And `${1:?message}`?
- [ ] What does exit code 0 mean, and why do scripts need meaningful exit codes?
- [ ] What's the difference between `&&` and `||`?
- [ ] Why use `while read -r` instead of `for line in $(cat file)`?
- [ ] What does `2>&1` do, and why does its position matter?
- [ ] What does each part of `set -euo pipefail` do?
- [ ] How do you debug a script that misbehaves?
---

# Day 5: Automation, Processes and Git

**Goal:** schedule a script to run on its own, manage running processes, understand the environment a script runs in, and version-control your work with git. Then pull the whole course together.
**Time:** about 2 hours.
**Topics:** `date`, environment variables and `PATH`, background jobs, `ps`, `kill`, `nohup`, `tmux`, `cron`, `git`, `ssh` and `scp`

## Warm-up (5 min, from memory)

From `~/bash-course/practice`:

1. Run `daily_summary.sh` for 2026-09-08 and print its exit code.
2. Run it for 2026-08-21, sending the error message to `/dev/null`, then print the exit code.
3. Write a one-line loop that prints every September date in `../lab/ref/business_days.txt`.
4. What do `-e`, `-u` and `-o pipefail` each do?

<details><summary>Answer</summary>

```bash
./daily_summary.sh 2026-09-08; echo $?            # 1 if you added the row-count check: 13 rows
./daily_summary.sh 2026-08-21 2>/dev/null; echo $?   # 1
while read -r d; do [[ "$d" == 2026-09* ]] && echo "$d"; done < ../lab/ref/business_days.txt
```

`-e` stops on the first failing command, `-u` makes undefined variables an error, and `-o pipefail` makes a pipeline fail if any stage fails, not just the last.
</details>

## 5.1 Dates (10 min)

Scheduled jobs almost always need today's date in a filename or argument.

```bash
date                          # full date and time
date +%F                      # 2026-10-07: ISO date, same as +%Y-%m-%d
date +%Y%m%d                  # 20261007
date '+%Y-%m-%d %H:%M:%S'     # with time
date +%T                      # time only
date +%A                      # day name
date +%u                      # day of week as a number: 1 = Monday ... 7 = Sunday
```

Other dates differ between Linux and macOS:

```bash
date -d yesterday +%F         # Linux, WSL, Git Bash
date -d '3 days ago' +%F      # Linux
date -v-1d +%F                # macOS equivalent of yesterday
```

Use the date in a script:

```bash
today=$(date +%F)
echo "Checking curve for $today"
```

**Always use ISO dates (`YYYY-MM-DD`) in filenames.** They sort correctly as plain text, which is why `ls`, `sort` and `comm` all worked on the lab files without any special handling.

## 5.2 The environment (15 min)

Every process runs with a set of **environment variables**.

```bash
env | head                    # show environment variables
echo "$HOME"                  # your home directory
echo "$USER"                  # your username
echo "$SHELL"                 # your login shell
echo "$PATH"                  # folders searched for commands, separated by :
```

When you type `grep`, bash searches each folder in `PATH`, in order, for a program called `grep`:

```bash
which grep awk python3        # where each command lives
type cd                       # "cd is a shell builtin": part of bash itself
type ls                       # may show an alias
```

**Shell variables versus environment variables.** A plain variable exists only in the current shell. `export` passes it on to programs you start:

```bash
MYVAR=hello
bash -c 'echo "child sees: $MYVAR"'     # empty: not exported
export MYVAR
bash -c 'echo "child sees: $MYVAR"'     # hello
```

This is how `DATA_DIR` reaches your scripts:

```bash
export DATA_DIR=~/bash-course/lab/data/curves
cd ~ && ~/bash-course/practice/daily_summary.sh 2026-09-03   # works from anywhere now
unset DATA_DIR
```

**Making settings permanent.** Commands in `~/.bashrc` run every time a new bash terminal opens (on macOS with zsh, the file is `~/.zshrc`). Add a shortcut:

```bash
echo "alias lab='cd ~/bash-course/lab'" >> ~/.bashrc
source ~/.bashrc              # reload without opening a new terminal
lab
pwd
```

Add your practice folder to `PATH`, so your scripts run by name from anywhere:

```bash
echo 'export PATH="$HOME/bash-course/practice:$PATH"' >> ~/.bashrc
source ~/.bashrc
which daily_summary.sh
```

(Your scripts use relative paths like `../lab`, so they'll still look for data relative to where you *are*. Setting `DATA_DIR` fixes that. This is exactly the kind of issue that breaks scripts under cron, below.)

## 5.3 Processes and background jobs (20 min)

Start a long-running command:

```bash
sleep 300
```

The terminal is now blocked. Press **Ctrl+C** to stop it.

Run it in the background instead, with `&`:

```bash
sleep 300 &                   # prints a job number and a process ID (PID)
jobs                          # list background jobs in this terminal
sleep 200 &
jobs
fg %1                         # bring job 1 to the foreground (Ctrl+C to stop it)
```

Pause and resume:

```bash
sleep 400                     # then press Ctrl+Z: suspends it
jobs                          # shows "Stopped"
bg                            # resume it in the background
jobs
```

Find and stop processes from anywhere:

```bash
ps aux | grep sleep           # every process; filter for sleep
ps aux | grep [s]leep         # trick: the [s] stops grep matching itself
pgrep -a sleep                # simpler: PIDs and command lines
kill <PID>                    # ask a process to stop (signal TERM); replace <PID> with a number
kill -9 <PID>                 # force it (signal KILL): last resort, no clean-up
pkill sleep                   # kill by name
jobs                          # should be empty now
```

Watch what's running:

```bash
top                           # live view: press q to quit, M to sort by memory, P by CPU
```

`htop` is a friendlier version if it's installed (`sudo apt install htop` on WSL or Linux, `brew install htop` on macOS).

**Surviving logout.** A background job normally dies when you close the terminal. On a remote server, that's a problem.

```bash
nohup ~/bash-course/practice/all_summaries.sh > ~/bash-course/practice/summaries.log 2>&1 &
cat ~/bash-course/practice/summaries.log
```

`nohup` ignores the hang-up signal sent when you disconnect. Run that from inside `~/bash-course/practice` so the script's relative paths work.

**tmux (optional).** For interactive sessions on servers, `tmux` is better than `nohup`: it keeps whole terminal sessions alive, and you can reattach later. If it's installed (`sudo apt install tmux` or `brew install tmux`):

```bash
tmux new -s work              # start a session called work
# ...run anything...
# press Ctrl+B, then D, to detach
tmux ls                       # list sessions
tmux attach -t work           # reattach
exit                          # inside tmux: ends the session
```

## 5.4 Scheduling with cron (25 min)

`cron` runs commands on a schedule. Each user has a **crontab** (cron table).

```bash
crontab -l                    # list your scheduled jobs ("no crontab" is fine)
crontab -e                    # edit them (choose nano if asked)
```

**Can you run cron here?**

- **Linux:** yes.
- **WSL:** cron isn't running by default. Start it with `sudo service cron start`.
- **macOS:** yes, though recent versions may ask for permission. If jobs don't run, give your terminal Full Disk Access in System Settings → Privacy & Security.
- **Git Bash:** no cron. Read this section and write the lines anyway; understanding the syntax is what matters for interviews.

**Syntax.** Five time fields, then the command:

```
┌───────── minute (0–59)
│ ┌─────── hour (0–23)
│ │ ┌───── day of month (1–31)
│ │ │ ┌─── month (1–12)
│ │ │ │ ┌─ day of week (0–7; 0 and 7 are Sunday)
│ │ │ │ │
* * * * *  command
```

| Line | Runs |
|---|---|
| `* * * * *` | every minute |
| `*/5 * * * *` | every 5 minutes |
| `0 9 * * *` | 09:00 every day |
| `30 17 * * 1-5` | 17:30 Monday to Friday |
| `0 6 1 * *` | 06:00 on the 1st of each month |
| `0 */2 * * *` | every 2 hours, on the hour |

**Practice: a job that runs every minute.**

1. Run `crontab -e` and add this line (use your real home path from `echo $HOME`):

   ```
   * * * * * date >> /home/yourname/bash-course/cron_test.log
   ```

2. Save and exit, wait two minutes, then:

   ```bash
   cat ~/bash-course/cron_test.log
   ```

   You should see one timestamp per minute.

3. Remove the line with `crontab -e`, and check with `crontab -l`.

**The three classic cron traps.**

1. **`%` means newline in a crontab.** `date +%F` must be written `date +\%F` inside crontab.
2. **Cron's environment is almost empty.** It doesn't read your `.bashrc`, its `PATH` is minimal, and it starts in your home directory. Use absolute paths everywhere, and `cd` to the right folder first.
3. **Output disappears** unless you redirect it. Always append stdout and stderr to a log.

A correct line for the daily summary:

```
30 17 * * 1-5 cd /home/yourname/bash-course/practice && ./daily_summary.sh "$(date +\%F)" >> daily.log 2>&1
```

Also remember that cron uses the server's time zone. A job set for 17:30 on a server running in UTC fires at 18:30 London time in summer.

**Practice:** write (but don't need to install) cron lines for each of these:

1. Run `all_summaries.sh` every weekday at 07:00.
2. Run a clean-up script at 23:45 on the last weekday of each month. Is that possible with the five fields? (Think about it, then check the answer.)
3. Run a check every 15 minutes between 08:00 and 18:00 on weekdays.

<details><summary>Answer</summary>

```
0 7 * * 1-5 cd /home/yourname/bash-course/practice && ./all_summaries.sh >> summaries.log 2>&1
*/15 8-17 * * 1-5 /home/yourname/bash-course/practice/check.sh >> /home/yourname/check.log 2>&1
```

Question 2 is a trick: standard cron can't express "last weekday of the month". The usual solution is to run the job on candidate days and let the script decide whether to proceed, for example by checking with `date` whether tomorrow is in a new month. Saying this in an interview shows you know cron's limits.

For question 3, `8-17` covers 08:00 to 17:45; add a separate `0 18 * * 1-5` line if you need exactly 18:00 too.
</details>

In real systematic-trading environments, jobs with dependencies ("run the check only after the feed has landed") usually move to a scheduler like **Airflow**, which Voleon's job ad mentions. Cron is still the foundation, and the place to start.

## 5.5 Git (30 min)

Git records versions of your files so you can see what changed, undo mistakes and work on changes in parallel.

**One-off setup:**

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

**Put your practice scripts under version control:**

```bash
cd ~/bash-course/practice
git init
git status                    # everything is "untracked"
```

Tell git to ignore generated files:

```bash
printf '*.log\nout.txt\n' > .gitignore
git status                    # the .log files have disappeared from the list
```

The basic cycle is **edit → stage → commit**:

```bash
git add daily_summary.sh .gitignore        # stage specific files
git status                                 # staged files are listed under "Changes to be committed"
git commit -m "Add daily curve summary script"
git add .                                  # stage everything else that isn't ignored
git commit -m "Add practice scripts"
git log --oneline                          # history, one line per commit
```

Now change something and look at the difference:

```bash
echo '# Owner: your name' >> daily_summary.sh
git status                    # modified
git diff                      # exactly what changed: + added lines, - removed lines
git add daily_summary.sh
git commit -m "Add owner comment"
git log --oneline
```

Undo an unwanted edit before committing:

```bash
echo 'broken line' >> daily_summary.sh
git diff
git restore daily_summary.sh  # throw away uncommitted changes to this file
git diff                      # nothing
```

**Branches.** A branch lets you work on a change without touching the main version:

```bash
git switch -c add-slope-check         # create a branch and switch to it (older: git checkout -b)
echo '# TODO: alert if 2s10s moves more than 5bp' >> daily_summary.sh
git commit -am "Note slope alert idea"   # -a stages every modified tracked file
git switch main
tail -2 daily_summary.sh              # the TODO isn't here: it's only on the branch
git merge add-slope-check
tail -2 daily_summary.sh              # now it is
git branch                            # list branches; * marks the current one
git branch -d add-slope-check         # delete the merged branch
```

**Practice: create and resolve a merge conflict.** Conflicts happen when two branches change the same line. Everyone meets them, and interviewers like to ask about them.

```bash
mkdir -p ~/bash-course/gitlab && cd ~/bash-course/gitlab
git init
echo 'THRESHOLD_BP=15' > config.sh
git add config.sh && git commit -m "Add config"

git switch -c tighten
echo 'THRESHOLD_BP=10' > config.sh
git commit -am "Tighten threshold to 10bp"

git switch main
echo 'THRESHOLD_BP=20' > config.sh
git commit -am "Loosen threshold to 20bp"

git merge tighten             # CONFLICT
git status                    # "both modified: config.sh"
cat config.sh
```

You'll see:

```
<<<<<<< HEAD
THRESHOLD_BP=20
=======
THRESHOLD_BP=10
>>>>>>> tighten
```

The top half is your current branch (`HEAD`, here `main`); the bottom half is the branch being merged. To resolve it, edit the file so it contains what you actually want, with the marker lines removed:

```bash
echo 'THRESHOLD_BP=10' > config.sh       # or edit it in VS Code, which shows "Accept Current / Incoming" buttons
git add config.sh                        # marks the conflict as resolved
git commit -m "Merge tighten: use 10bp threshold"
git log --oneline --graph                # see the two branches join
```

To back out of a merge instead of resolving it: `git merge --abort`.

**Working with a remote (GitHub).** Once you have a GitHub repository:

```bash
git remote add origin https://github.com/yourname/bash-course.git
git push -u origin main       # first push
git pull                      # get others' changes
git clone <url>               # copy an existing repository
```

Interview vocabulary worth knowing: `git fetch` downloads changes without merging; `git pull` is fetch plus merge. `git rebase` replays your commits on top of another branch to keep history linear, instead of creating a merge commit.

## 5.6 Remote servers: `ssh` and `scp` (5 min, read only)

You won't need a server to finish this course, but Voleon's research runs on Linux machines you'd connect to remotely:

```bash
ssh user@server.example.com                     # open a shell on a remote machine
scp report.csv user@server:/data/reports/       # copy a file to it
scp user@server:/data/logs/app.log .            # copy a file from it
ssh user@server 'tail -n 50 /data/logs/app.log' # run one command remotely
```

Everything you've learned this week works the same once you're connected.

## 5.7 Lab: Part E and the full run-through (20 min)

1. Complete **Part E, questions 17–19** in `exercises.md`.
2. Put your `check_feed.sh` from Part D under git, with at least three commits showing it evolving.
3. **Full run-through:** reset the data with `bash setup_lab.sh` (from `~/bash-course`), then run your health check across every business day and produce the summary from question 16. Time yourself. Then explain each of the eight problems out loud in one sentence: what it is, how your script caught it, and why it would matter if it reached a model.

If you have time, try the **Stretch** section at the end of `exercises.md`.

## Day 5 checklist

- [ ] Why use ISO dates in filenames?
- [ ] What's the difference between a shell variable and an exported environment variable?
- [ ] What is `PATH`, and why can't you run `script.sh` without `./`?
- [ ] How do you run a command in the background, list jobs, and bring one back?
- [ ] What's the difference between `kill` and `kill -9`?
- [ ] What does `nohup` do, and when is `tmux` better?
- [ ] Read the cron line `30 17 * * 1-5` aloud.
- [ ] What are the three classic cron traps?
- [ ] What's the difference between `git add` and `git commit`?
- [ ] How do you resolve a merge conflict?
- [ ] What's the difference between `git fetch` and `git pull`?

---

# Appendix A: Interview Quick-Fire Questions

Cover the right-hand column and answer aloud.

| Question | Short answer |
|---|---|
| `>` vs `>>` | Overwrite vs append. |
| What does `2>&1` do? | Sends stderr (2) to wherever stdout (1) currently points. |
| What is `$?` | The exit code of the last command; 0 means success. |
| `&&` vs `;` | `&&` runs the next command only if the previous one succeeded; `;` always runs it. |
| Single vs double quotes | Double quotes expand `$VAR` and `$(...)`; single quotes are literal. |
| Find the 10 largest files under a folder | `du -ah dir \| sort -rh \| head -10` |
| Count unique values in column 3 of a CSV | `cut -d, -f3 file \| sort \| uniq -c \| sort -rn` |
| Replace text in place across files | `sed -i 's/old/new/g' *.csv` (macOS: `sed -i ''`) |
| Show lines 100–120 of a big file | `sed -n '100,120p' file` |
| Watch a log for errors live | `tail -f app.log \| grep --line-buffered ERROR` |
| Run a job that survives logout | `nohup cmd &`, or a `tmux` session |
| What's using CPU? | `top` or `htop`; `ps aux --sort=-%cpu \| head` on Linux |
| What is a shebang? | The `#!` first line naming the interpreter for a script. |
| Why `set -euo pipefail`? | Stop on errors, undefined variables and failed pipeline stages. |
| Why can't `wc -l` reliably count CSV records? | Quoted fields can contain newlines; messy CSV needs a real parser. |
| When would you *not* use bash? | Complex logic, real CSV parsing, statistics, anything needing tests and maintenance: use Python. |

The last two are worth raising unprompted. Knowing where bash stops being the right tool is exactly the judgement a data team wants to see.

# Appendix B: Common Errors and Fixes

| Error | Usual cause | Fix |
|---|---|---|
| `Permission denied` running `./script.sh` | No execute permission | `chmod +x script.sh` |
| `command not found` for your script | Current folder isn't in `PATH` | Run it as `./script.sh` |
| `name: command not found` on `name = value` | Spaces around `=` | `name=value` |
| `No such file or directory` with a valid file | Unquoted path containing spaces, or the wrong working directory | Quote it: `"$f"`; check `pwd` |
| `$'\r': command not found` | Script saved with Windows line endings | In VS Code, click `CRLF` in the bottom bar and change it to `LF`; or `sed -i 's/\r$//' script.sh` |
| `unbound variable` | `set -u` and a misspelt or unset variable | Fix the name, or use `${VAR:-default}` |
| Script stops silently partway | `set -e` and a command that returned non-zero (often `grep` finding nothing) | Add `\|\| true` where failure is acceptable |
| `comm` gives wrong results | Inputs not sorted | `comm <(sort a) <(sort b)` |
| `uniq` doesn't remove duplicates | Input not sorted | `sort \| uniq` |
| `sort` puts 10 before 2 | Text sort | `sort -n` |
| awk prints nothing for `$2` | Wrong separator | Add `-F,` for CSV |
| Cron job doesn't run, or runs but fails | Unescaped `%`, relative paths, minimal `PATH` | `\%`, absolute paths, `cd` first, log with `>> file 2>&1` |
| `sed -i` error on macOS | BSD `sed` needs a suffix argument | `sed -i '' 's/a/b/' file` |

# Appendix C: Daily Cheat Sheet

```bash
# Day 1: navigation and files
pwd; ls -lht; cd -; mkdir -p a/b; cp -r src dst; mv old new; rm -r dir
head -n 5 f; tail -n +2 f; wc -l < f; less f; find . -name '*.csv' -mtime -1; chmod +x s.sh

# Day 2: filtering and counting
grep -c -v -i -w -E -l -n -H 'pat' f
cut -d, -f2,3 f; sort -t, -k2,2 -k3,3nr; cut -d, -f2 f | sort | uniq -c | sort -rn
comm -23 <(sort a) <(sort b); tr ',' '\t'; sed -E 's/x(.*)y/\1/'; sed -n '2,5p'

# Day 3: awk
awk -F, 'FNR > 1 && $3 != "" && $3 > 4 { print FILENAME, $2, $3 }' *.csv
awk -F, 'FNR > 1 { s[$2] += $3; n[$2]++ } END { for (k in s) print k, s[k]/n[k] }' *.csv | sort
awk -F, -v t=10Y '$2 == t { if (p != "") print $1, ($3 - p) * 100; p = $3 }' *.csv

# Day 4: scripting
#!/usr/bin/env bash
set -euo pipefail
DATE="${1:?usage: $0 DATE}"; DIR="${DATA_DIR:-./data}"
if [[ ! -f "$f" ]]; then echo "missing" >&2; exit 1; fi
while read -r line; do ...; done < file
cmd > out.log 2>&1; bash -x script.sh

# Day 5: automation and git
cmd &; jobs; fg %1; ps aux | grep [n]ame; kill PID; nohup cmd > log 2>&1 &
crontab -e:   30 17 * * 1-5 cd /abs/path && ./check.sh "$(date +\%F)" >> health.log 2>&1
git add f; git commit -m "msg"; git log --oneline; git diff; git switch -c br; git merge br
```
