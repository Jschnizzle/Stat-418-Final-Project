# Final Project — Working Context & Handoff Brief

> **Purpose:** Portable context for future threads. Captures what's in this folder, the datasets and their gotchas, the analysis code written so far, key decisions/findings, and open threads. Point a new thread at this file to get oriented fast.
>
> Scope note: this is the **working-root** context (the actual analysis in progress). A separate, more course-oriented brief lives at `World Cup Project/Context/Context.md` (dataset scaffold) and `Demonstration/Context/Context.md` (the instructor's example). This file is the day-to-day one.

_Last updated: 2026-07-10 (rev 2 — men's/women's filter bug documented; league downloaders added)_

---

## 1. The course (one-paragraph reminder)

STAT 418 (UCLA, Summer 2026, instructor Christopher Barr). Final project (30% of grade, **due Wed Jul 29**) has three deliverables: a **LaTeX PDF**, reproducible **R code**, and a **PowerPoint** presented live. Scoring rewards breadth of course tools and using a dataset you care about. In-scope classes: **3 (EDA/Tableau), 4 (Joins/SQL), 5 (Inference), 6 (Prediction/`ranger`), 9 (Text), 11 (Data→Theory).** Key R packages: `sqldf`, `ranger`.

---

## 2. Folder map (working root = `Final Project/`)

| Path | What it is |
|---|---|
| `worldcupdata_processing.R` | **Class 5 inference** — builds a team-per-tournament table from the datahub World Cup CSVs via `sqldf`, fits several `lm()` point models. |
| `transformed_data.csv` | Exported `model_df` from the script above (see §4 — **had a men's/women's bug; fix via `filter_transformed_mens.R`**). |
| `transformed_data_all.csv` | Backup of the full (men's + women's) table, written by `filter_transformed_mens.R` before it overwrites `transformed_data.csv`. |
| `filter_transformed_mens.R` | Filters `transformed_data.csv` down to men's-only (581 → 445 rows) using the source gender labels (see §4). |
| `england_pl_scoring_analysis.R` | Exploratory: England WC group-stage performance vs. Premier League scoring (see §6). |
| `england_pl_scoring_plots.png` | Output of the script above (created when it's run in R). |
| `worldcup_data/` | The datahub World Cup dataset — 38 CSVs (relational: tournaments, teams, squads, players, matches, goals, bookings, …). |
| `premierleague_data/` | 33 EPL season CSVs (`season-YYYY.csv`) + README/schema/datapackage (see §5). |
| `FrenchLigue1.txt`, `SpanishLaLiga.txt`, `GermanBundesliga.txt` | datahub URL lists for three more leagues (36 links each, same schema as EPL). |
| `frenchligue1_data/`, `spanishlaliga_data/`, `germanbundesliga_data/` | Created when `download_leagues.py` is run (33 season CSVs + metadata each). |
| `Old Data/` | Archived CSVs (international results, goalscorers, shootouts, housing). Cloud-only; not part of current work. |
| `download_worldcup.py`, `download_premierleague.py` | Python downloaders that pull the two datahub datasets from URL lists in `footballworldcup.txt` / `PremierLeague.txt`. |
| `download_leagues.py` | Generalized downloader — loops the three league URL lists into `<stem>_data/` folders (see §5). |
| `Book1.twb` | Tableau workbook (early EDA). Two `*.png` charts are early figures. |
| `World Cup Project/` | Self-contained project scaffold built this thread (see §7). |
| `Demonstration/` | The instructor's example project scaffold (reference only). |

**Folder permissions:** read/write/delete all confirmed working. Deleting files needs to be enabled once per folder (already enabled for `Final Project/`).

---

## 3. `worldcupdata_processing.R` — structure & gotchas

Reads 8 tables from `worldcup_data/` and assembles a modeling table, **one row per team per group-stage campaign in a men's World Cup** (outcome = group-stage **points**, 0–9).

**Predictor blocks (each aggregated to tournament_id × team_id):**
- `team_experience` → `prior_tournaments`: # of prior men's WCs the team appeared in (clean, backward-only via `t2.year < tp.year`).
- `squad_stats` → `squad_size`, `avg_age`, `forward_share`, `defender_share`, `avg_career_tournaments`.
- `squad_experience` *(added this thread)* → `avg_prior_wc`, `max_prior_wc`, `debutant_share` (see §4).
- `cards` → `yellows`, `reds`, `total_cards` (bookings only exist **from 1970**).
- `host` → `is_host`; `manager` → `foreign_manager`.

**Models:** `m1` (goals), `m2` (prior_tournaments + age + forward_share), `m2c` *(added; Jeremy then extended it to)* `points ~ avg_prior_wc + avg_age + forward_share + defender_share`, `m3` (cards, 1970+), `m4` (host + confederation + year), `m5` (experience + foreign_manager + year). Residual diagnostics via `plot(m3)`.

**Gotchas baked in:**
- 78 players have `birth_date = 'not available'`; a 4-digit-year `GLOB` guard sets those to NULL before averaging age (otherwise `avg_age` blows up ~1400).
- Group-stage filter `stage_name IN ('group stage','first group stage')` keeps `points` comparable (excludes the 1974–82 second group stages).
- `players.count_tournaments` counts a player's **whole career incl. future** → leaky. Prefer `avg_prior_wc` for clean inference.

**🐛 KNOWN BUG — men's filter leaks women's rows.** The `base`, `team_experience`, and `squad_experience` blocks filter with `WHERE tournament_name LIKE '%Men''s%'`. SQLite's LIKE is **case-insensitive**, and "Wo**men's**" contains "men's", so **women's tournaments pass the filter**. Result: `model_df` (and the exported `transformed_data.csv`) is 581 rows = **445 men's + 136 women's**, not men's-only. Fix at source by changing those clauses to `LIKE '%FIFA Men''s%'` (women's read "FIFA Women's", which does not contain "FIFA Men's") or add `AND tournament_name NOT LIKE '%Women''s%'`. **Not yet patched in the script** — see §9.

**⚠️ Consequence:** the models fit so far (`m1`–`m5`, `m2c`) were trained on the **mixed** 581-row table. Re-run them on the corrected 445-row men's table once the source filter is patched.

---

## 4. Key derived metric: `squad_experience` (clean, non-leaky)

Per player, count prior men's WCs they appeared in (`squads` joined to `tournaments`, filtered `t2.year < tp.year`), then aggregate to the squad:
- `avg_prior_wc` — mean prior-WC appearances across the squad.
- `max_prior_wc` — the veteran anchor.
- `debutant_share` — fraction of the squad at their first WC.

This is the backward-only alternative to the leaky `avg_career_tournaments`. **Sanity check:** Argentina 2002 → `avg_prior_wc` = 0.826, 9 debutants. In model `m2c`, `avg_prior_wc` was strongly positive (~+2.7 points per extra average prior WC, t≈8.5) — sensible.

### ⚠️ `transformed_data.csv` gotcha (and the fix)
It's the exported `model_df` (30 columns: `team_name`, `year`, `points`, `goals_for`, the engineered vars, etc.), and because of the §3 filter bug it **contains BOTH men's and women's rows** (581 = 445 men's + 136 women's) with **no gender column**. Women's WC years present: 1991, 1995, 1999, 2003, 2007, 2011, 2015, 2019, 2023.

**Two ways to isolate men's:**
1. **Robust (recommended):** run `filter_transformed_mens.R` — it reads the men's/women's label from `worldcup_data/group_standings.csv` (case-sensitive `grepl("Men's") & !grepl("Women's")`, which cleanly separates them because "Women's" has a lowercase m), keeps only men's `tournament_id`s, backs up the full table to `transformed_data_all.csv`, and rewrites `transformed_data.csv` as the 445-row men's-only table.
2. **Quick heuristic:** filter to the 4-year cycle `year %in% seq(1930, 2022, 4)` — verified to agree 100% with the id-based method, but relies on the year pattern rather than the source labels.

Every `tournament_id` maps to exactly one gender (0 ambiguous), so the id-based filter is bulletproof. This matters any time the data is joined to men's-only sources like the Premier League.

---

## 5. Premier League data (`premierleague_data/`)

Match-level EPL results, 1993/94–present, from Football-Data UK (via datahub). One row per game. Columns: `Date, HomeTeam, AwayTeam, FTHG, FTAG, FTR, HTHG, HTAG, HTR, Referee, HS, AS, HST, AST, HF, AF, HC, AC, HY, AY, HR, AR`.

**Coverage tiers:** 93/94–94/95 = scores only (42-team seasons, 462 games); 95/96–99/00 = + half-time; **00/01–present = full stats** (shots, fouls, corners, cards). 380 games/season in the 20-team era.

**Key limitation for national-team work:** the dataset is **clubs only — no player names, nationality, or club→country mapping** (and `worldcup_data` squads have no club field either). So PL data can only proxy the England national team at an **aggregate "state of English football"** level, not player-by-player. Candidate predictors identified: league scoring/shots/conversion/corners, discipline (cards/fouls), competitiveness (home-win/draw rates, GD spread), and top-club form as a talent proxy.

**Other leagues (added):** datahub URL lists for **French Ligue 1, Spanish La Liga, German Bundesliga** are in the folder. `download_leagues.py` pulls each into its own `<stem>_data/` folder (36 URLs = 33 season CSVs + metadata each). Same Football-Data schema as the EPL, so they slot straight into the same aggregation/scoring code — useful for extending the scoring analysis to other nations. Run it like the EPL downloader: `python download_leagues.py`.

---

## 6. `england_pl_scoring_analysis.R` — England WC vs. PL scoring

**Question:** does PL scoring being up/down *between* World Cups relate to England's group-stage performance?

**Two scoring angles, computed per season:**
- **League-wide** `league_gpg` = mean(`FTHG`+`FTAG`) over all matches.
- **Top clubs** `top_gpg` = goals scored per game by the **top `TOP_N`=6 clubs** (ranked by league points that season) — proxy for the England talent pool. Dynamic per season (not a fixed big-six).

**Window features** for each men's WC year Y over the inter-cup window (seasons ending in (Y-4, Y]): `mean`, `slope` (within-window trend), `delta` (last−first), `change` (this window mean − previous window mean). Built generically for both angles via `window_stats()` / `build_features()`.

**Merge & explore:** England men's group-stage rows, PL era → **n = 7** (1998, 2002, 2006, 2010, 2014, 2018, 2022). Correlations + `lm` + a 2×2 plot (rows = angles, left = change vs points, right = level vs goals-for).

England group-stage record used: points/goals-for = 1998 (6/5), 2002 (5/2), 2006 (7/5), 2010 (5/2), 2014 (1/2), 2018 (6/8), 2022 (7/9).

**Tentative findings (n = 7 — hypotheses, NOT conclusions):**
- League-wide: strongest link is between-cup **`change`** → points, r ≈ **−0.74**.
- Top-6: strongest link is within-window **`delta`/`slope`** → points, r ≈ **−0.57 / −0.45**.
- Both point the same way: England tended to do slightly *worse* in the group when domestic scoring was *rising*. Fragile at this sample size.

---

## 7. `World Cup Project/` scaffold (built this thread)

A self-contained parallel of `Demonstration/`, built around the **datahub 38-table World Cup dataset**:
```
World Cup Project/
├── Context/   (tailored Context.md + copied syllabus, lecture, timeline)
├── Analysis/  (Code/01_load_data.R [house style, downloads datahub CSVs],
│               Data/[38 CSVs + datapackage.json], EDA/WorldCup_EDA.twb)
├── Formatting/ (R style exemplars + 3 UCLA style-guide options: Marquee/Westwood/Bruin)
└── Project/   (empty class folders: 3, 4, 5, 6, 9, 11)
```
The scaffold's `Context.md` notes that `worldcupdata_processing.R` is effectively the Class 5 seed.

**House R style (from the Demonstration exemplars):** spaces inside parens `rm( list = ls() )`, `# ----` banners, `Title_Case`/`CamelCase` names. NB: `worldcupdata_processing.R` and `england_pl_scoring_analysis.R` use a tighter lower-case style — restyle if hand-in consistency matters.

**Visual style:** UCLA palette blue `#2774AE` / gold `#FFD100`; three options (Marquee / Westwood / Bruin) — **not yet chosen.** (Option 1 Marquee exists as HTML only, no PPTX.)

---

## 8. Decisions made

- Dataset for the main modeling: the **datahub relational World Cup dataset** (`worldcup_data/`).
- Clean experience metric adopted: **`avg_prior_wc`** over the leaky `avg_career_tournaments`.
- Side project: **England WC performance vs. PL scoring**, exploring both league-wide and top-6 angles.
- Project positioned **data-first** on the data→theory spectrum.

## 9. Open threads / next steps

- **Patch the men's filter bug in `worldcupdata_processing.R`** (§3): change `LIKE '%Men''s%'` → `LIKE '%FIFA Men''s%'` in the `base`, `team_experience`, `squad_experience` blocks, then **re-run models `m1`–`m5`/`m2c` on the corrected 445-row men's table.** (Run `filter_transformed_mens.R` now to clean the exported CSV in the meantime.)
- Move/restyle `worldcupdata_processing.R` into `World Cup Project/Project/Class 5 - Inference/`.
- Build out Classes 3, 4, 6, 9, 11 in the scaffold.
- PL side project robustness: try `TOP_N = 4` or a fixed big-six; swap outcome to `advanced`/stage reached; add non-scoring PL features (discipline, competitiveness).
- Pick a visual style option (Marquee / Westwood / Bruin).
- Decide the headline narrative; draft the LaTeX PDF and PPTX outlines.
- Consider Class 6 `ranger` random-forest predicting advancement (train-old/test-recent).
