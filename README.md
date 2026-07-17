# STAT 418 Final Project — Soccer / World Cup Analysis

Final project for **STAT 418 (UCLA, Summer 2026)**. The project models national-team
performance at the FIFA World Cup and explores how domestic league scoring relates to
England's tournament results, using a range of course tools (EDA/Tableau, SQL joins,
inference, prediction, text, and data-to-theory).

## Data

- **`worldcup_data/`** — the datahub relational World Cup dataset (38 CSVs: tournaments,
  teams, squads, players, matches, goals, bookings, managers, referees, …). This is the
  primary source for the modeling work.
- **`premierleague_data/`**, **`spanishlaliga_data/`**, **`germanbundesliga_data/`**,
  **`frenchligue1_data/`** — Football-Data (UK) season CSVs, 1993/94–present, one row per
  match. Used for the domestic-scoring side analysis.
- **`transformed_data.csv`** — exported modeling table (`model_df`), one row per team per
  group-stage campaign. **`transformed_data_all.csv`** — the full men's + women's backup.

> **Known data note:** the raw export in `transformed_data.csv` originally mixed men's and
> women's tournaments because SQLite's `LIKE '%Men''s%'` is case-insensitive and matches
> "Women's". Run `filter_transformed_mens.R` to isolate the men's-only table (445 rows), or
> patch the source filter in `worldcupdata_processing.R` to `LIKE '%FIFA Men''s%'`.

## Code

| File | Purpose |
|---|---|
| `worldcupdata_processing.R` | Builds the team-per-tournament modeling table via `sqldf` and fits several `lm()` point models (Class 5 — inference). |
| `filter_transformed_mens.R` | Filters the exported table down to men's-only using source gender labels. |
| `england_pl_scoring_analysis.R` | Explores England's World Cup group-stage performance vs. Premier League scoring trends. |
| `download_worldcup.py`, `download_premierleague.py`, `download_leagues.py` | Python downloaders that pull the datahub / Football-Data CSVs from the URL lists (`footballworldcup.txt`, `PremierLeague.txt`, and the per-league `*.txt` files). |

## Other contents

- **`World Cup Project/`** — a self-contained project scaffold (Context, Analysis, Formatting,
  and per-class folders) built around the World Cup dataset.
- **`Book1.twb`, `Final_Project_EDA.twb`** — Tableau workbooks for EDA.
- **`*.png`** — early exploratory figures.
- **`Context.md`** — detailed working brief: datasets, gotchas, decisions, and open threads.

## Reproducing

1. Run the Python downloaders to (re)fetch the raw league / World Cup CSVs if needed.
2. Run `worldcupdata_processing.R` to build the modeling table, then `filter_transformed_mens.R`
   for the men's-only version.
3. Run `england_pl_scoring_analysis.R` for the domestic-scoring side analysis.

Key R packages: `sqldf`, `ranger`.
