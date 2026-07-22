# Final Project — Working Context & Handoff Brief

> **Purpose:** Portable context for future threads. Captures what's in this folder, the datasets and their gotchas, the analysis code written so far, key decisions/findings, and open threads. Point a new thread at this file to get oriented fast.
>
> Scope note: this is the **working-root** context (the actual analysis in progress). A separate, more course-oriented brief lives at `World Cup Project/Context/Context.md` (dataset scaffold) and `Demonstration/Context/Context.md` (the instructor's example). This file is the day-to-day one.

_Last updated: 2026-07-21 (rev 4 — model-only split script + `DATA_PIPELINE.md` added; per-row `row_id`/`campaign` keys added for Tableau; GitHub repo situation clarified; Tableau bubble-plot recipes worked out (§11))_

---

## 1. The course (one-paragraph reminder)

STAT 418 (UCLA, Summer 2026, instructor Christopher Barr). Final project (30% of grade, **due Wed Jul 29**) has three deliverables: a **LaTeX PDF**, reproducible **R code**, and a **PowerPoint** presented live. Scoring rewards breadth of course tools and using a dataset you care about. In-scope classes: **3 (EDA/Tableau), 4 (Joins/SQL), 5 (Inference), 6 (Prediction/`ranger`), 9 (Text), 11 (Data→Theory).** Key R packages: `sqldf`, `ranger`.

---

## 2. Folder map (working root = `Final Project/`)

| Path | What it is |
|---|---|
| `worldcupdata_processing.R` | **Class 5 inference** — builds a team-per-tournament table from the datahub World Cup CSVs via `sqldf`, fits several `lm()` point models. **Still carries the men's-filter bug (§3) if reused.** |
| `poisson_mens_groupstage.R` | **Build + model** — men's-1970+ Poisson model of group-stage `points_std` (single 3-1-0 rule). Rebuilds the table from `worldcup_data/` (filter bug fixed at source), pruned predictors, stepwise AIC/BIC selection, pseudo-R², team-clustered SEs. Now also writes the `row_id`/`campaign` keys (§11). See §10. |
| `poisson_mens_groupstage_model.R` | **NEW (rev 4)** — model-only split: loads `mens_groupstage_1970on.csv` and runs §§2–7 of the modeling (no data build). Re-relevels `conf` to UEFA after load (CSV flattens the factor). Use this for iterating on the model without re-running the `sqldf` pipeline (§11). |
| `mens_groupstage_1970on.csv` | Clean 368-row men's-1970+ modeling table. **Now 35 cols** — `row_id` (1–368) and `campaign` ("Team Year") added as the first two columns (rev 4) so each row plots as its own mark in Tableau (§11). |
| `DATA_PIPELINE.md` | **NEW (rev 4)** — plain-English writeup of every transformation/aggregation from the 8 raw `worldcup_data/` CSVs to `mens_groupstage_1970on.csv` (source tables, filters, predictor blocks, `points_std` recompute, 1970+ cut, which cols are usable predictors). |
| `CLAUDE_CODE_TASK.md` | Handoff brief for running `poisson_mens_groupstage.R` via Claude Code on Jeremy's machine (needs R, which the Cowork sandbox lacks). |
| `diagnostics.png` | Poisson residual diagnostics (written when the script runs). |
| `transformed_data.csv` | Exported `model_df` from `worldcupdata_processing.R` (see §4 — **had a men's/women's bug; fix via `filter_transformed_mens.R`**). |
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
- **Poisson track (2026-07-21):** outcome recomputed to a single 3-1-0 rule (`points_std = 3*wins + draws`) to kill the 1994 scoring-rule artifact; modeling window fixed to **men's, 1970+**. Approach = Poisson GLM with **stepwise AIC/BIC selection** on a pre-pruned predictor set; significance via **team-clustered SEs**; overdispersion handling (quasi-Poisson / negative binomial) **explicitly de-scoped**.

## 9. Open threads / next steps

- **Run `poisson_mens_groupstage.R` on Jeremy's machine via Claude Code** (`CLAUDE_CODE_TASK.md`) — it needs R, which the Cowork sandbox doesn't have; pipeline logic was validated by a Python replication only. (The model-only `poisson_mens_groupstage_model.R` still needs a real R run too.)
- **Push rev-4 changes to GitHub** — the project already lives on `main` at `https://github.com/Jschnizzle/Stat-418-Final-Project` (the `Various-Projects` branch idea was dropped). Only 7 files are new/changed vs the remote: the 6 new files (`CLAUDE_CODE_TASK.md`, `DATA_PIPELINE.md`, `diagnostics.png`, `mens_groupstage_1970on.csv`, `poisson_mens_groupstage.R`, `poisson_mens_groupstage_model.R`) + modified `Context.md`. The Cowork sandbox can't push (no credentials); do it from Git Bash or Claude Code on Jeremy's machine — commit only those files (the ~20 other "changed" files are just CRLF/LF line-ending noise). See §11.
- **Decide AIC vs BIC model** from the stepwise output; optionally add `f_structural` as a pre-specified comparison to sidestep post-selection inference; VIF-check the two experience terms (`prior_tournaments` vs `avg_prior_wc`).
- Men's-filter bug is **fixed at source in `poisson_mens_groupstage.R`**, but **`worldcupdata_processing.R` still carries it** (§3): if reused, change `LIKE '%Men''s%'` → `LIKE '%FIFA Men''s%'` in the `base`, `team_experience`, `squad_experience` blocks and re-run `m1`–`m5`/`m2c` on the corrected 445-row table.
- Move/restyle `worldcupdata_processing.R` (and the new Poisson script) into `World Cup Project/Project/Class 5 - Inference/`.
- Build out Classes 3, 4, 6, 9, 11 in the scaffold.
- PL side project robustness: try `TOP_N = 4` or a fixed big-six; swap outcome to `advanced`/stage reached; add non-scoring PL features (discipline, competitiveness).
- Pick a visual style option (Marquee / Westwood / Bruin).
- Decide the headline narrative; draft the LaTeX PDF and PPTX outlines.
- Consider Class 6 `ranger` random-forest predicting advancement (train-old/test-recent).

---

## 10. Poisson model for men's group-stage points (added 2026-07-21)

New this session: a self-contained Poisson modeling script, a Claude Code handoff brief, and a newly-surfaced data gotcha (the 1994 scoring-rule break). Grew out of a request to fit a Poisson model on "most/all" variables for men's WC data, 1970+.

### 🐛 NEW GOTCHA — the `points` column changes scoring rule in 1994
Raw `points` in `group_standings.csv` uses **2 points for a win before 1994** and **3 points from 1994 on** (verified: matches the 2-pt rule 100% for 1970–1990, the 3-pt rule 100% for 1994–2022). This shifts both the scale (max 6 vs 9) **and** the value of a draw relative to a win, so raw `points` is not comparable across eras. **Fix adopted:** recompute one rule for all years — `points_std = 3*wins + draws` — the outcome in the new script. (A percentage-of-max normalization was considered and rejected: it fixes the scale but not the draw re-weighting, and turns a count into a bounded proportion that breaks Poisson.)

### Modeling window (why men's + 1970+)
- Cards (`bookings`) only exist from 1970.
- From 1970 on every team plays exactly **3 group games** → fixed denominator, no Poisson offset needed (script `stopifnot`s `played == 3`).
- Men's isolated at source via `LIKE '%FIFA Men''s%'` (case-insensitive-LIKE bug fixed): **445 men's rows** all years, **368** after the 1970 cut.

### Data restrictions catalogued (these drove predictor pruning)
- **Deterministic identities / tautology** — excluded as predictors of the points outcome: `wins`, `draws`, `losses` (`points_std = 3*wins+draws`), `goals_for`/`goals_against`/`goal_difference` (`GD = GF − GA` exactly), `points_raw`, `advanced` (derived from ranking).
- **Collinear clusters (keep one each):** experience — kept `prior_tournaments` (team) + `avg_prior_wc` (squad), r≈0.49, different constructs; dropped `max_prior_wc`/`debutant_share` (avg_prior_wc vs debutant_share r=−0.95) and `avg_career_tournaments` (leaky, counts future). Discipline — kept `total_cards`, dropped `yellows`/`reds` (yellows~total_cards r=0.99).
- **Sparse factor level:** confederation `OFC` = 2 rows (New Zealand) → collapsed to "OTHER"; UEFA is the baseline.
- **Non-independence:** the same nation recurs across tournaments → **team-clustered SEs** (not plain Poisson SEs) for honest significance.

### Script contents — `poisson_mens_groupstage.R`
Rebuilds the men's table from `worldcup_data/` (all predictor blocks re-run with the fixed filter), computes `points_std`, filters to 1970+, collapses `conf`, centers `year_c` (4-yr units on 1994), writes `mens_groupstage_1970on.csv` + `diagnostics.png`. Model specs:
- `f_candidate`: `points_std ~ prior_tournaments + avg_prior_wc + avg_age + forward_share + defender_share + squad_size + is_host + foreign_manager + conf + year_c + total_cards`.
- `f_structural`: same minus `total_cards` (pre-tournament only; cleaner inference story).
- **Selection:** base `step()` — AIC & BIC, forward & both — on the pre-pruned pool; default reported model = `sel_aic_both`. (BIC penalty `k = log n` → usually fewer terms. Post-selection p-values are optimistic.)
- **Overall fit:** **no true R² for a Poisson GLM.** Report McFadden pseudo-R² (~0.10) and deviance pseudo-R² (~0.26), deviance GOF p-value, AIC/BIC, LRT vs null.
- **De-scoped this session (removed at Jeremy's request):** AER dispersiontest, quasi-Poisson, negative binomial. Kept team-clustered SEs (that's non-independence, not dispersion). Caveat retained: fit shows mild overdispersion (deviance/df ≈ 1.47), so model-based p-values are slightly optimistic; clustered SEs partially compensate.

### Validation
R is not available in the Cowork sandbox, so the full pipeline was **independently replicated in Python** (pandas + statsmodels): 368 rows, `played == 3` throughout, no missing predictors, Poisson converges with finite coefficients, and sensible significant terms (`prior_tournaments` +, `is_host` + with RR≈1.58, confederation effects strongest for UEFA/CONMEBOL). Actual R run still pending on Jeremy's machine — see `CLAUDE_CODE_TASK.md`.

---

## 11. Session rev 4 (2026-07-21) — docs, model-only split, Tableau keys, GitHub

Follow-on session. No new modeling decisions; the work was packaging, reproducibility, and viz prep.

### `DATA_PIPELINE.md` (new)
Plain-English walkthrough of the whole build: the 8 source tables + join key `(tournament_id, team_id)`, the base-table filters (`LIKE '%FIFA Men''s%'` + group-stage restriction), all six predictor aggregations with their gotchas (age GLOB guard, backward-only experience, leaky cols), the `points_std = 3*wins + draws` recompute, the 1970+ cut (445→368), the `conf`/`year_c` derivations, the final 33-col shape, and which columns are usable predictors vs excluded. Documents the **current** `poisson_mens_groupstage.R` pipeline only (not the older buggy `worldcupdata_processing.R` path).

### Model-only split — `poisson_mens_groupstage_model.R` (new)
Jeremy wanted to iterate on the model without re-running the `sqldf` build every time. Split the script: the build stays in `poisson_mens_groupstage.R`; the new file just `read.csv("mens_groupstage_1970on.csv")` then runs selection → fit → overall-fit → clustered SEs → diagnostics (former §§4–7). **Key subtlety preserved:** CSV storage flattens the `conf` factor to plain text, so the model-only script re-applies `relevel(factor(conf), ref = "UEFA")` — without it the confederation baseline would default to alphabetical and coefficients would read differently. Kept the `played == 3` and `year >= 1970` guardrails as sanity checks on the loaded table. (Jeremy also added `rm( list = ls() )` at the top of this file.)

### Per-row identifiers for Tableau — `row_id` + `campaign` (added to the CSV **and** the build script)
`mens_groupstage_1970on.csv` had no unique row key, so Tableau averaged marks by `team_name`/`team_id`. Added two columns as the first two fields: `row_id` (integer 1–368) and `campaign` (readable label, e.g. "Soviet Union 1970" = `team_name` + `year`). Verified both `(team_name, year)` and `(tournament_id, team_id)` are unique across all 368 rows, so either is a valid key. Added to the live CSV (now 35 cols) and baked into `poisson_mens_groupstage.R` (built right before `write.csv`, placed first) so regeneration keeps them. Neither is a model predictor — the formulas reference columns by name, so the Poisson fit is unaffected. **Tableau tip recorded:** drag `campaign` (or `row_id`) onto Detail, or turn off Analysis → Aggregate Measures, to force one mark per campaign.

### GitHub repo — situation clarified
The dedicated repo `https://github.com/Jschnizzle/Stat-418-Final-Project` **already exists with the whole project on `main`** (everything, no per-project-branch convention — that convention belongs to the separate `Various-Projects` repo, which was the initial plan before switching). Diffed the remote `main` against the local folder: only **7 files** genuinely differ (the 6 rev-4 new files + `Context.md`); the other ~20 "changed" files are pure **CRLF/LF line-ending noise** (identical after stripping `\r`) and should NOT be committed. The Cowork sandbox **cannot push** (no stored GitHub credentials; pasting a PAT is off-limits) — the push must run from Git Bash or Claude Code on Jeremy's machine, staging only the 7 real files onto `main`. Ready-to-paste commands/prompt were provided in-thread. **Not yet pushed.**

### Tableau bubble-plot recipes (worked out, not built)
Two count-scaled scatter plots discussed; general rule for both: **size by area, not radius**; optionally add a redundant color-by-count and a reference line.
- **Goals-for vs goals-against (count bubbles):** 368 campaigns → 92 distinct (GF, GA) points, counts 1–16 (densest = 2–2 with 16). Options laid out (Tableau native / R `ggplot2::geom_count` / Plotly HTML / Python) — nothing built yet.
- **`defender_share` vs `points_std` (Tableau):** the "make the axis pills **Dimensions** but keep them **Continuous**, then put **Number of Records** on Size" recipe. `defender_share` has only 20 distinct values (small squads → coarse fractions), so raw counting works (88 cells, max 14); optional 0.05 bins give bolder bubbles (38 cells, max 27). Noted the y-axis naturally **skips 8** (`3*wins + draws` over 3 games can't equal 8), and suggested a linear Trend Line since this is predictor-vs-outcome.
