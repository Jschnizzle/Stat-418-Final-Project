# STAT 418 Final Project — Context & Handoff Brief (datahub World Cup)

> **Purpose of this file:** Shared context for parallel work sessions. Read this first to get oriented fast. It captures the course, logistics, requirements, the chosen dataset and its provenance, the per-class analysis plan, existing assets, the house style, and the project folder structure. Keep it updated as decisions are made.
>
> **Note:** This scaffold mirrors the `Demonstration/` example folder, but is built around a *different* World Cup dataset — the **datahub.io multi-table relational dataset** (38 CSVs), not the single match-level `worldfootballR` table used in the demo.

_Last updated: 2026-07-10_

---

## 1. Course at a glance

**STAT 418: Tools in Data Science** (UCLA, Summer 2026) — a practical tour of the tools a working data scientist reaches for, plus an argument about wielding them with judgement. The throughline is one coherent workflow: **acquire → understand → combine/query at scale → model (inference *and* prediction) → communicate.** Guiding AI ethic: *"delegate aggressively while verifying relentlessly."*

### Logistics (from syllabus)
- **Instructor:** Christopher D. Barr — cdbarr@gmail.com (office hours by appointment).
- **Lectures:** Mon & Wed, 6:00–7:50pm, June 22 – July 29, 2026. Room PAB 1749.
- **Prerequisites:** Statistics 404 and 405.
- **Software:** RStudio (R) — required, from posit.co. Also **Tableau** (free student license at tableau.com/academic/students) and **Claude Desktop**. **Key R packages: `sqldf` and `ranger`.**

### Grading
| Component | Weight | Notes |
|---|---|---|
| Attendance & Participation | **30%** | May miss only 1 class; speak ≥1×/class. |
| Homework | 20% | Nine short assignments (see §3). |
| Midterm | 20% | In class, Wed Jul 15. |
| **Final project** | **30%** | **Due Wed Jul 29.** |

Honor code: work must be your own; discussion encouraged but write your own work.

---

## 2. The final project

### Required deliverables
1. **A PDF with narrative content, built using LaTeX.**
2. **R code** — reproducible analysis.
3. **A PowerPoint presentation** — delivered live on the final day (Jul 29); attendance mandatory.

### Known evaluation levers
- **Use a dataset you genuinely care about** (explicit professor requirement). ✅ Chosen — see §5.
- **Incorporate as many course topics as possible.** Breadth of demonstrated tools is a primary scoring driver.

### Current scope decision
Building against **six in-scope classes only: 3, 4, 5, 6, 9, and 11.** (Classes 2 and 10 — Claude Desktop and LLMs — de-scoped for now.)

---

## 3. Term timeline & homework cadence

The project is **scaffolded by homework** — each of the nine assignments has three sections: a **Review** (class just finished), a **Preview** (next class), and a **Project** section that advances the final project in small increments. HW is assigned at end of class, emailed before the next class; **no late work**.

| Class | Date | Topic | Homework |
|---|---|---|---|
| 1 | Mon Jun 22 | Class Summary | HW1 assigned |
| 2 | Wed Jun 24 | Claude Desktop | HW1 due; HW2 assigned |
| 3 | Mon Jun 29 | EDA + Tableau | HW2 due; HW3 assigned |
| 4 | Wed Jul 1 | Joins and SQL | HW3 due; HW4 assigned |
| 5 | Mon Jul 6 | Models for Inference | HW4 due; HW5 assigned |
| 6 | Wed Jul 8 | Models for Prediction | HW5 due; HW6 assigned |
| 7 | Mon Jul 13 | Midterm Review | HW6 due |
| 8 | Wed Jul 15 | **Midterm** | — |
| 9 | Mon Jul 20 | Text Data | HW9 assigned |
| 10 | Wed Jul 22 | AI / LLMs | HW9 due; HW10 assigned |
| 11 | Mon Jul 27 | From Data to Theory | HW10 due; HW11 assigned |
| 12 | Wed Jul 29 | **Final Project due** | HW11 due |

---

## 4. The "data to theory" framing (Class 11 / project spine)

Value is created along a spectrum from **data** to **theory**: (1) *data-first* — present profoundly valuable data clearly, possibly with little analysis beyond visualization; or (2) *theory-first* — develop new methods usable across domains. **This project is positioned as data-first** (a rich, well-structured relational history of the World Cup), with an optional small methodological gesture (e.g. a clean, non-leaky "squad experience → group-stage points" model — see §7).

---

## 5. The dataset — CHOSEN ✅

**Location:** `Analysis/Data/` — **38 CSV files** plus `datapackage.json`, `README.md`.

**What it is:** A **relational, multi-table history of the FIFA World Cup** (men's and women's), covering **30 tournaments, 1930–2023**. Unlike a single match table, this is a normalized schema: tournaments, teams, squads, players, matches, goals, bookings, referees, managers, standings, and pre-computed summary tables all join on shared keys (`tournament_id`, `team_id`, `player_id`, `match_id`).

**Provenance:** Downloaded from **datahub.io/football/worldcup** — each table has a stable r-link URL (listed in the top-level `footballworldcup.txt`). Acquisition is reproducible via `Analysis/Code/01_load_data.R` (R, house style) or the top-level `download_worldcup.py`. The datahub package publishes `datapackage.json` (metadata & schema) and per-table CSVs.

### Table inventory (row counts)
| Table | Rows | What it holds |
|---|---|---|
| `tournaments.csv` | 30 | One row per tournament (year, host, winner, stage flags). |
| `teams.csv` | 88 | Team master (code, confederation, region, men's/women's flags). |
| `group_standings.csv` | 626 | One row per team per group — **points, W/D/L, GF/GA, advanced.** |
| `matches.csv` | 1,248 | Match-level results and metadata. |
| `goals.csv` | 3,637 | One row per goal (minute, scorer, stage). |
| `bookings.csv` | 3,178 | Cards (yellow/red/second-yellow); **only from 1970 on.** |
| `squads.csv` | 13,843 | One row per player per team per tournament. |
| `players.csv` | 10,401 | Player master (birth_date, position flags, `count_tournaments`). |
| `player_appearances.csv` | 27,432 | One row per player per match (starter/sub). |
| `substitutions.csv` | 10,222 | Substitution events. |
| `team_appearances.csv` | 2,496 | One row per team per match. |
| `manager_appointments.csv` | 637 | Manager per team per tournament. |
| `manager_appearances.csv` | 2,538 | Manager per match. |
| `managers.csv` | 475 | Manager master (nationality). |
| `referees.csv` / `referee_appointments.csv` / `referee_appearances.csv` | 493 / 668 / 1,248 | Referee master + assignments. |
| `qualified_teams.csv` | 625 | Qualification/performance per team-tournament. |
| `host_countries.csv` | 31 | Host nation per tournament. |
| `stadiums.csv` | 240 | Venue master. |
| `groups.csv` / `tournament_stages.csv` / `tournament_standings.csv` | 159 / 155 / 120 | Group and stage structure; final standings. |
| `attendance.csv` / `attendance-by-edition.csv` | 964 / 22 | Match and tournament attendance. |
| `award_winners.csv` / `awards.csv` | 200 / 8 | Golden Boot etc. |
| `confederations.csv` | 6 | Confederation lookup. |
| Summary tables (`top-scorers-summary`, `tournament-goals-summary`, `discipline-by-tournament-summary`, `dirtiest-matches-summary`, `goal-timing-by-tournament-summary`, `goals-by-minute-summary`, `tournament-appearances`) | 8–90 | Pre-aggregated views handy for EDA/plots. |

### Useful characteristics & quirks
- **Rich join structure** — this is a SQL/`sqldf` playground; the natural project spine is joining squads → players → tournaments and standings → teams.
- **Men's vs. women's** — most tables carry `tournament_name LIKE '%Men''s%'` / women's; filter deliberately so metrics stay comparable.
- **Cards only from 1970** — `bookings.csv` is empty before then; discipline models must be restricted to `year >= 1970`.
- **Dirty birth dates** — 78 players have `birth_date = 'not available'`; guard with a 4-digit-year regex/GLOB before computing ages (otherwise averages blow up).
- **Leakage watch** — `players.count_tournaments` counts a player's *whole* career (incl. future tournaments). For clean inference, derive a **backward-only** experience measure from `squads` + `tournaments.year` instead (see §7).
- **Second group stages (1974–1982)** — filter `stage_name IN ('group stage','first group stage')` so `points` (0–9) is comparable across eras.

---

## 6. Per-class analysis plan (simplified)

**Class 3 — EDA & Tableau**
- Goals-per-match and attendance trends over time (men's vs. women's).
- Tableau dashboard from `Analysis/EDA/WorldCup_EDA.twb` (already started).
- Spot outliers (biggest blowouts, record crowds, dirtiest matches).

**Class 4 — Joins & SQL (`sqldf`)**
- Reshape/join squads ↔ players ↔ tournaments; build standings via `GROUP BY`.
- Join an external host/champion lookup (a `host_countries.csv` already exists in-schema).

**Class 5 — Inference**
- Linear models of **group-stage points** on experience, age, discipline, host advantage, foreign manager (this is exactly what the top-level `worldcupdata_processing.R` already does — see §7).

**Class 6 — Prediction** *(use the `ranger` package — named in syllabus)*
- Random forest to predict advancement / match outcome; honest train-on-old / test-on-recent split.

**Class 9 — Text (regex)**
- Parse messy string fields (birth dates, name matching for foreign-manager flag, stage-name normalization).

**Class 11 — Data to Theory**
- Frame as a data-first project on a rich relational dataset; optional small method (clean squad-experience → points).

---

## 7. Existing assets (already in the folder / repo)

- **`../worldcupdata_processing.R`** (top level of Final Project) — the **Class 5 inference** work: builds a team-per-tournament modeling table from the 38 CSVs via `sqldf`, then fits five `lm()` options for group-stage points. Recently extended with a **clean, non-leaky `squad_experience`** block (`avg_prior_wc`, `max_prior_wc`, `debutant_share`) and model `m2c`. This is the natural seed for `Project/Class 5 - Inference/`.
- **`Analysis/Data/`** — the 38-table datahub dataset (raw pull).
- **`Analysis/EDA/WorldCup_EDA.twb`** — Tableau workbook (copied from the top-level `Book1.twb`); Class 3 work underway.
- Top-level chart exports: `Average Goals per Country.png`, `Average Goals and Penalties For per Country.png` — early EDA figures.
- **`Formatting/`** — style references (see §8).

---

## 8. House style & formatting

**R code style** (consistent across `Formatting/Binomial.R`, `Formatting/Central Limit Theorem.R`, and the demo's `01_load_data.R`): spaces *inside* parentheses — `rm( list = ls() )`; long `# ----` section-divider comment banners; `Title_Case` / `CamelCase` variable names. Match this style in new R scripts. (The two `Formatting/*.R` files are simulation demos — Binomial draws, Central Limit Theorem — reused here as **style exemplars**, not project analysis.)

> Note: the existing `worldcupdata_processing.R` uses a *different* (lower-case, tight-paren) style. If consistency matters for the final hand-in, consider restyling it to match the house style above when it moves into `Project/Class 5`.

**Visual style guide** (`Formatting/Style Guide/` + options as HTML/PPTX): three UCLA-themed design options — **Option 1 "The Marquee", Option 2 "Westwood", Option 3 "Bruin"** — for the PDF and PowerPoint. Shared UCLA palette: blue **#2774AE** and gold **#FFD100**, with deep-navy/blue accents (#005587, #0A2540) and light neutrals; serif + sans + mono type system. **Pick one option** for consistent deck/PDF styling. _(Style option not yet selected.)_

---

## 9. Project folder structure

```
World Cup Project/
├── Context/
│   ├── Context.md                       ← this file
│   ├── Lecture 01.pdf                    ← course topic list
│   ├── Statistics 418 Syllabus.pdf       ← logistics & grading
│   └── Statistics 418 Timeline.xlsx      ← term schedule + HW cadence
├── Analysis/
│   ├── Code/01_load_data.R               ← data acquisition (datahub worldcup)
│   ├── Data/  (38 CSVs + datapackage.json + README.md)   ← the dataset
│   └── EDA/WorldCup_EDA.twb              ← Tableau workbook (started)
├── Formatting/
│   ├── Binomial.R, Central Limit Theorem.R   ← R style exemplars
│   ├── Style Guide/Style_Guide.pptx
│   └── Style-Guide-Option-{1 Marquee,2 Westwood,3 Bruin}.{html,pptx}
└── Project/
    ├── Class 3 - EDA and Tableau         (empty)
    ├── Class 4 - Joins and SQL           (empty)
    ├── Class 5 - Inference               (seed: ../worldcupdata_processing.R)
    ├── Class 6 - Prediction               (empty)
    ├── Class 9 - Text Data                (empty)
    └── Class 11 - Data to Theory          (empty)
```

---

## 10. Decisions made so far

- Scope narrowed to **classes 3, 4, 5, 6, 9, 11**.
- **Dataset chosen:** the **datahub.io relational World Cup dataset** (38 tables, 1930–2023).
- **Positioning:** data-first on the data→theory spectrum.
- Per-class analysis plan drafted (§6).
- Project folder scaffolding created (§9), self-contained (Formatting + Context assets copied in).

---

## 11. Open questions / next steps

- Move/restyle `worldcupdata_processing.R` into `Project/Class 5 - Inference/` and split acquisition vs. modeling.
- Build out each class's analysis in its `Project` subfolder (R scripts + outputs), matching the house R style (§8).
- **Select a visual style option** (Marquee / Westwood / Bruin) for the PDF + deck.
- Decide the specific research question / headline narrative for the PDF.
- Draft the LaTeX PDF structure and the PowerPoint outline.
- Extend the Tableau workbook for the Class 3 dashboard.

---

## 12. Per-class project to-do list

Work each item in its `Project/Class N …` subfolder. Save R scripts (matching the house style in §8), exported figures/tables, and short notes there. Every class should produce (a) reproducible R code, (b) one or two figures/tables for the PDF, and (c) a slide or two for the deck.

### Class 3 — EDA & Tableau
- [ ] R script that loads the core CSVs, runs summary stats, and produces 2–3 polished plots (goals-per-match over time, attendance over time, men's vs. women's). Save figures as PNG/PDF into the class folder.
- [ ] Extend `Analysis/EDA/WorldCup_EDA.twb` into a small dashboard; export an image or `.twbx`.
- [ ] Document EDA findings/outliers (biggest blowout, record crowd, dirtiest match) as narrative bullets.

### Class 4 — Joins & SQL (`sqldf`)
- [ ] Use `sqldf` to build a team-per-tournament / team-per-match table from squads, standings, and teams.
- [ ] Build a standings/leaderboard query (`GROUP BY` team & year) and a self-join for head-to-head records.
- [ ] Join the host/champion info (`host_countries.csv` + `tournaments.csv`) for host-advantage and continent analyses.

### Class 5 — Models for Inference
- [ ] Adopt/restyle `worldcupdata_processing.R`: five `lm()` options for group-stage points, incl. the clean `avg_prior_wc` experience model (`m2c`).
- [ ] Export a tidy coefficient table + residual diagnostics for the PDF.
- [ ] Write up the accuracy↔interpretability tension.

### Class 6 — Models for Prediction (`ranger`)
- [ ] Random forest (use `ranger`) to predict advancement or match outcome from pre-match features; report accuracy + confusion matrix.
- [ ] Honest out-of-sample eval: train on older tournaments, test on recent; compare to the Class 5 linear models.
- [ ] Save a variable-importance plot; discuss inference-vs-prediction contrast.

### Class 9 — Text Data (regex)
- [ ] Regex-clean messy string fields (4-digit birth-year guard; stage-name normalization; country/team name matching for the foreign-manager flag).
- [ ] Produce a before/after example table for the PDF.

### Class 11 — From Data to Theory
- [ ] Write the framing section positioning the project as **data-first**, justified by the richness of the relational World Cup schema.
- [ ] Optionally sketch a small reusable method (clean squad-experience → expected points).
- [ ] Synthesize into the headline narrative and key visuals for the deck + PDF conclusion.
