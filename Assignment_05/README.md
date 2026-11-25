# Assignment 5 — Technical Analysis using R, Development Phase

**Bhanu Rachamalla | BDA400 | 24 November 2026**

Nine standalone indicator scripts implement the supplied templates using base R. The accompanying report explains calculations, tests, historical stock examples, filters and trading-signal rules.

## Run

Use R 4.4.3 or a compatible recent version. No contributed R packages, downloads or API keys are needed. Open this folder as the working directory (not the repository root):

```r
setwd("path/to/TechnicalAnalysis/Assignment_05")
source("load_all.R")
source("tests.R")
source("run_analysis.R")
```

Or run in a terminal from this folder:

```sh
Rscript tests.R
Rscript run_analysis.R
python3 independent_check.py
```

Python 3 is optional and used only for an independent validation reference. Existing CSV outputs and console logs can be reviewed without rerunning. Individual files work alone, for example:

```r
source("indicators/sma.R")
sma(c(10,12,15,20,18,22,25,24,21),3)
# 12.33333 15.66667 17.66667 20 21.66667 23.66667 23.33333
```

## Files

- `indicators/`: one R script for each of the nine required functions.
- `CONVENTIONS.md`: exact signatures, return types, alignment and conflicting pseudocode details.
- `variants.R`: separately named standard/causal RSI and crossover alternatives.
- `tests.R`, `evidence/`: 65 R checks, 51 independent Python series/aggregation checks and genuine console logs.
- `data/`: unchanged Yahoo Finance snapshots for AAPL, MSFT and GOOGL, inherited from Assignment 2, with provenance manifest.
- `run_analysis.R`, `outputs/`: date/source/weekly filters, indicators, screen, signal candidates and charts.
- `Rachamalla_Bhanu_CA_BDA400_A05.pdf`: submission cover and implementation report.

## Data and interpretation

Each stock has 61 daily sessions, 2 January–28 March 2024. Assignment 5 indicators use **Close**, not Adjusted. The inherited manifest's Adjusted setting describes Assignment 2 statistics, not this workflow. The cached prices are real historical data, not current quotes or synthetic records. Weekly aggregates include partial observed weeks. No missing market sessions are filled.

Read `CONVENTIONS.md` before grading: the supplied pseudocode differs from its prose for regression, RSI, StochRSI and crossover types. Required functions preserve pseudocode; standard variants remain separate. No instructor test file was provided. Global-normalized StochRSI is noncausal and excluded from trading rules.

Trading outputs are candidate actions, not executed orders or a position-aware backtest. Close-based signals are paired with the next observed session's open. Costs, slippage, holdings and profitability are not modeled.

## AI attribution

ChatGPT assisted with implementation, tests, independent checks, charts and documentation on 24 November 2026. The exact backend model/version was not exposed in this interface. See `AI_APPENDIX.md`. Execution occurred in a remote workspace using native R, not on the student's computer. No student manual review or instructor confirmation is claimed.

## References

- Assignment 5 brief supplied in this conversation, pages 1–20.
- Yahoo Finance cached snapshots and `data/source_manifest.json` (downloaded during Assignment 2).
- R documentation: https://stat.ethz.ch/R-manual/R-devel/library/base/html/00Index.html
