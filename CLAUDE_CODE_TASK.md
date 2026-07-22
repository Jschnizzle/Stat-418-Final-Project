# Task for Claude Code — run the men's World Cup Poisson analysis

## Objective
Execute `poisson_mens_groupstage.R` end to end, confirm it runs clean, and report
back the model results and fit diagnostics. Do **not** rewrite the analysis logic —
the script is already designed; your job is to run it, fix any environment/pathing
issues, and summarize the output.

## Environment
- OS: Windows. Working directory / project root:
  `C:\Users\jerem\OneDrive\Documents\Stat_418\Final Project`
- The script expects to be run **from that project root**, because it reads
  `worldcup_data/` via the relative path `data_dir <- "worldcup_data"`.
- R is required (RStudio not needed). If `Rscript` is not on PATH, locate it
  (typically `C:\Program Files\R\R-<version>\bin\Rscript.exe`) or install R from
  https://cran.r-project.org before proceeding.

## What the script does (context, so you can sanity-check the output)
`poisson_mens_groupstage.R` builds a Poisson-ready table of **men's** World Cup
**group-stage** campaigns from **1970 onward** and fits a candidate Poisson GLM.
Key design points already baked in — leave these intact:
- Men's filter uses `LIKE '%FIFA Men''s%'` (fixes an earlier case-insensitive bug
  where "Women's" leaked in). Zero women's rows should remain.
- Outcome is `points_std = 3*wins + draws` — a single 3-1-0 rule applied to all
  years, so the pre/post-1994 scoring-rule change does not distort the count.
- From 1970 on every team plays exactly 3 group games; the script `stopifnot()`s
  this so no exposure offset is needed.
- Predictors are pruned to avoid tautology/collinearity (no wins/draws/losses/
  goals/goal_difference as predictors of points_std).

## Required R packages
Core (must have): `sqldf`  (variable selection uses base `step()`, no extra pkg)
Optional (only for team-clustered SEs; script skips gracefully if missing):
`sandwich`, `lmtest`

Install any that are missing:
```r
install.packages(c("sqldf","sandwich","lmtest"))
```
Note: `sqldf` pulls in `RSQLite`.

## Steps
1. `cd` to the project root (path above).
2. Make sure the packages above are installed (install the missing ones).
3. Run the script from the project root:
   ```
   Rscript poisson_mens_groupstage.R
   ```
   (Or in an R session: `setwd("<project root>"); source("poisson_mens_groupstage.R")`.)
4. Capture the console output.

## Expected results (use these to verify it ran correctly)
- Console prints: **`Modeling table: 368 rows x ... cols (men's, 1970+)`**.
  (445 men's rows exist across all years; 368 after the 1970+ cut.)
- `points_std` range **0–9**, mean ≈ **4.1**, var ≈ **6.3**.
- The `stopifnot(all(model_df$played == 3))` guardrail passes silently.
- A file **`mens_groupstage_1970on.csv`** is written to the project root.
- Stepwise selection prints four term sets (`AIC both`, `AIC forward`,
  `BIC both`, `BIC forward`); BIC will usually keep fewer terms than AIC.
- The chosen Poisson model converges and prints a McFadden and a deviance
  pseudo-R², a deviance GOF p-value, AIC/BIC, and an LRT vs the null.
- Sensible significant terms include `prior_tournaments` (+), `is_host` (+,
  rate ratio ≈ 1.5–1.6), and confederation effects (UEFA/CONMEBOL strongest).
- Four residual diagnostic plots are saved to **`diagnostics.png`** in the project
  root (the script does this automatically so it works under `Rscript`); they also
  render to the plot pane in an interactive RStudio/R session.

## If something breaks
- **"cannot open file 'worldcup_data/...'"** → you're not in the project root, or
  `worldcup_data/` isn't present. `cd` to the root; confirm the folder exists.
- **`stopifnot` fails on `played == 3`** → a pre-1970 row slipped through or the
  data changed; check the `year >= 1970` filter and the group-stage `stage_name`
  filter. Report rather than silently patching.
- **sqldf / RSQLite install issues on Windows** → ensure Rtools is not required
  for binary installs (CRAN provides Windows binaries); try
  `install.packages("sqldf", type="binary")`.
- **A diagnostics package won't install** → the script skips those blocks with a
  message and the core Poisson fit still runs; note which were skipped.

## Deliverable back to me
1. Confirmation it ran, with the row count (368) above.
2. The four stepwise term sets (AIC/BIC × forward/both) and which model was
   chosen (`pois <- sel_aic_both` by default).
3. The `summary()` of the chosen Poisson model (coefficients, SEs, p-values)
   and the overall-fit lines (McFadden + deviance pseudo-R², GOF p-value,
   AIC/BIC, LRT vs null).
4. The team-clustered coefficient table (if sandwich + lmtest installed).
5. Flag anything surprising (non-convergence, a term that flips sign vs the
   expectations above, or AIC and BIC disagreeing sharply on the model).
