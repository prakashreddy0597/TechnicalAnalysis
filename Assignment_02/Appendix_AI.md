# AI assistance and provenance

**Student:** Bhanu Rachamalla · **Course:** BDA400 · **Assignment:** 2

**Tool:** ChatGPT; model/version not exposed. **Date:** 24 November 2026.

The user supplied the PDF titled *BDA400 Assignment 2 — Technical Analysis using R, Preliminary Stage* and requested to proceed with Assignment 2. The attachment defines the required functions, outputs and report; its instructions were reviewed as task specifications, not treated as proof that installation or verification had already happened.

## Actual user directions

- “okay lets go to assignment 2”
- Stock selection: “Use AAPL, MSFT, and GOOGL.”
- Installation preference: “i dont want to install can you complete with you creating evidence?”
- The user created and supplied https://github.com/prakashreddy0597/TechnicalAnalysis, and explicitly chose a public repository. Its identity and upload permissions were verified through the connected GitHub account.

## Assistance supplied

The assistant created R functions, downloaded actual historical prices through quantmod, executed the statistics and charts, and cross-checked them using Python's separate csv/statistics implementation. It installed quantmod and TTR using R's `install.packages()` in the workspace. An initial downloader/certificate problem was fixed by using the configured system curl downloader, without disabling TLS verification.

The assistant downloaded Posit's actual RStudio Server package, extracted it into a user-owned workspace, connected it to the existing R installation, ran the real IDE, executed R commands through its console, and captured screenshots. This is real remote-workspace evidence, not a claim that R/RStudio were installed on the student's Windows PC. No installer progress screen, GitHub account-registration screen or personal student action was fabricated.

## Method decisions and limitations

- Use a fixed historical window for reproducibility and cache each stock's raw data.
- Calculate statistics on adjusted close, keeping raw OHLCV fields available.
- Report sample standard deviation, not population SD or return volatility.
- Use a trailing five-observation SMA, leaving the initial four values missing.
- Treat all-distinct prices as having no unique mode; do not use base R's `mode()` as a numerical mode estimator.
- Keep unrounded numeric values in CSV; round only presentation tables.
- Explicitly count excluded missing adjusted prices.

The project uses real historical market data as requested in this assignment's PDF, not the synthetic data used in other assignments. Its results are descriptive and are not trading recommendations. Data-provider revisions may affect a future online run; cached files and hashes preserve the submitted snapshot.

No independent student manual verification, instructor approval of the remote alternative, or GitHub publication is claimed unless separately confirmed in the final report. Calculations and documentation are AI-assisted; the student must review them before submission.


## Publication

Repository: https://github.com/prakashreddy0597/TechnicalAnalysis. The user created the repository because creation through the integration was not permitted. The assistant uploaded the assignment folders, code, frozen data, generated outputs, genuine screenshots and reports. Final read-back verification is recorded separately. As a public repository, it can be viewed by the instructor without an invitation.
