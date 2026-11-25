# AI assistance record

Tool: ChatGPT; exact backend model/version not exposed. Date: 25 November 2026.

## Actual user prompt

The user provided the full Assignment 6 brief, “Technical Analysis using R, Visualization Phase (15%)”, requesting an R Shiny dashboard, Yahoo stock retrieval, chart selection, indicators with toggles, trading rules and annotations, repository code and a submission cover. Prior conversation selected AAPL, MSFT and GOOGL and authorized work in the public TechnicalAnalysis repository. The follow-up “Have you done” requested status during implementation.

## Key design refinements

- Replace the illustrative, undefined geom_ma(), geom_rsi() and geom_macd() calls with real ggplot2 layers.
- Detect crossover events using current and previous relationships, instead of continuously labeling fast > slow as Buy.
- Preserve price/RSI/MACD units using aligned facets with independent y-scales.
- Compute indicators on buffered historical data before restricting the visible dates.
- Add selectable Yahoo and Stooq providers, explicit saved-data fallback and error messages.
- Validate date/period inputs and do not assume same-close signal execution.

AI assisted with the actual code, technical tests, browser verification, figures and report. Test logs and screenshots are generated artifacts from real execution, not invented student actions. The supplied brief has no personal-reflection deliverable, so no first-person reflection or manual-review claim is fabricated.
