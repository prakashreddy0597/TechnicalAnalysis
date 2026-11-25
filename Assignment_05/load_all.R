# BDA400 Assignment 5 — base-R implementation, 24 November 2026.
# AI-assisted by ChatGPT (model/version not exposed); user supplied the brief.
# No indicator package or fitted-model helper is used in this implementation.
# See CONVENTIONS.md for literal-pseudocode choices and known ambiguities.
# Run from the Assignment_05 folder. No package installation is required.
for (file in c("sma.R", "ema.R", "macd.R", "stdev.R", "linreg.R", "rsi.R",
               "stoch_rsi.R", "crossover.R", "crossunder.R")) {
  source(file.path("indicators", file))
}
source("variants.R")
