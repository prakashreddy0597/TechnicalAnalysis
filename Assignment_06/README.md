# Assignment 6 — Technical Analysis using R, Visualization Phase

**Bhanu Rachamalla · BDA400 · 25 November 2026**

An interactive R Shiny stock dashboard for AAPL, MSFT and GOOGL. The application offers Yahoo Finance downloads, optional Stooq downloads, visibly labeled saved-data fallback, chart selection, technical indicators and causal crossover annotations.

## Run

Install R (tested with 4.4.3) and these packages once:

```r
install.packages(c("shiny", "ggplot2", "quantmod"))
```

Then open this folder as the working directory and run:

```r
setwd("path/to/TechnicalAnalysis/Assignment_06")
shiny::runApp(".", launch.browser = TRUE)
```

All dashboard implementation code is in `app.R`, separated into four labeled sections. Shiny launches the browser interface. No API key is required. `zoo` and `xts` are installed as quantmod dependencies. Live providers require internet access; provider availability is outside the application’s control.

## Controls

- Choose a stock, provider, visible date range and Daily / Weekly / Monthly bars.
- Select Candlestick, Line or Area price charts.
- Independently toggle Moving Averages, RSI and MACD. Moving averages overlay price; RSI and MACD have aligned panels in the same chart with separate y-scales.
- Adjust fast/slow MA periods, RSI period, MACD periods and signal period.
- Choose MA crossover or MACD crossover with an RSI entry ceiling.
- Toggle Buy/Sell annotations; view Hold status and the candidate event table.
- Fetch/refresh and download the visible indicator data as CSV.

The default saved Yahoo snapshot spans 2 January–28 March 2024. It is real historical data, not a current quote. Change to Yahoo Finance (live) to fetch new data. If fallback is selected and live retrieval fails, the status explicitly reports both the failure and saved source. Dates outside the snapshot coverage produce an explanatory message. The fallback checkbox can be disabled to require a successful live request.

## Calculations and timing

Close prices are used consistently. SMA windows are complete-window averages. EMA starts at the first observed price. Standard Wilder RSI is seeded once after the first period price changes, correcting the nonstandard duplicate seed update in Assignment 5’s literal pseudocode. No global-normalized StochRSI is used.

The app retrieves up to 600 prior calendar days for indicator warm-up. Indicators and signals are computed on chronological bars before the visible-date filter, avoiding artificial resets when the display window changes. Weekly/monthly OHLCV uses first Open, maximum High, minimum Low, last Close and summed Volume. The final available week/month can be partial; the bar date is its final available session. A visible starting aggregate bar can include sessions before the selected start. Selected periods count bars, not calendar days. A short saved weekly/monthly series can legitimately contain only warm-up Hold values.

A Buy requires the fast line to become strictly greater after being less than or equal; Sell requires the reverse. Remaining bars are Hold. This implements actual crossover events, correcting the brief’s example which tests only current relative position. MACD entries additionally require available RSI below the adjustable ceiling, and signals are suppressed until MACD slow + signal − 1 bars. That cutoff reduces but does not eliminate EMA initialization sensitivity.

Signals are calculated at bar close. The next available bar's open is exported as an illustrative candidate execution price; no same-close fill is assumed and no next bar outside the selected end is exposed. The app is a stock watchlist and signal tool, not a position-aware backtest or a holdings/performance ledger. It does not claim returns or execute orders.

## Validation and evidence

Run `Rscript tests.R` from this folder. `evidence/` contains actual console results, browser screenshots, example output and live-provider checks. Browser checks exercise chart types, indicator toggles, timeframes, stock changes, annotations and invalid inputs. Screenshots show the real Shiny interface, not a recreated mockup. See the submission PDF for the evidence summary.

## Limitations and safeguards

Yahoo and Stooq use potentially different historical adjustment conventions; the provider is displayed and the two sources are not silently mixed. Saved fallback is always labeled. The application rejects missing/invalid OHLCV, duplicate dates, invalid date ranges and invalid indicator periods. Only one selected stock is shown at a time; the three stocks form a watchlist. No hypothetical returns, holding quantities or portfolio values are invented. Signals can whipsaw and omit costs, liquidity, risk controls and position sizing.

## AI attribution and references

ChatGPT assisted with code, testing and documentation on 25 November 2026. The exact backend model/version was not exposed. `AI_APPENDIX.md` records the actual prompt context and corrections. Native R execution and browser testing occurred in the remote workspace, not on the student’s PC. No independent student review or instructor sign-off is claimed.

References: user-provided Assignment 6 brief (pages 1–7); https://shiny.posit.co/r/getstarted/ ; https://ggplot2.tidyverse.org/ ; https://www.quantmod.com/ ; Yahoo Finance; https://stooq.com/ . The saved-data provenance manifest is retained from Assignment 2; its Adjusted-price setting applies to that earlier assignment, while this dashboard uses Close.
