# Assignment 3 — Prompting R Functions with AI

Bhanu Rachamalla · BDA400 · 24 November 2026

## Deliverables

- `Rachamalla_AI_RFunction_Assignment.R`: initial, intermediate and final functions, all commented.
- `Rachamalla_Reflection.docx`: 150–200-word final reflection draft, five-sentence debugging reflection and explicit attribution.
- `Rachamalla_Bhanu_CA_BDA400_A03.pdf`: supplementary review report with prompts, tests, results and line-by-line explanation.
- `Appendix_AI.md`: exact applied prompt sequence, key responses and authorship record.
- `evidence/Console_Output.txt`: actual native R execution log, not an AI-chat screenshot.
- `evidence/test_summary.csv`: comparison and expected-rejection outcomes.
- `evidence/Debugging_Record.txt`: the observed missing-value, method-convention and named-index issues.
- `verification/Verification_Workbook.xlsx`: formulas for the student to recalculate and verify in Sheets.

## Task and method

Remove numerical outliers using Tukey hinge-based fences, keeping original data order and returning an exclusion audit. Only synthetic vectors are used. The final function uses `fivenum()` so its supported-data outliers align with `boxplot.stats()`.

Values exactly on a fence are kept. NA/NaN are removed by default and audited separately; `na.rm=FALSE` with missing values deliberately errors. Infinite values, classed objects, matrices, complex values, coefficient zero and overflow are unsupported and explicitly rejected. Empty and all-missing supported inputs return an empty clean vector and undefined fences. This is an outlier-screening rule, not proof that an unusual observation is incorrect.

## Run

From this folder in R or RStudio:

```r
source("Rachamalla_AI_RFunction_Assignment.R")
result <- remove_outliers(c(10, 15, 999, 20, 25, NA_real_))
result$clean
result$outlier_positions
```

Reproduce the full synthetic test run:

```sh
Rscript run_tests.R
```

The function needs base R only. The executed environment was native R 4.4.3 in a managed Linux workspace; no student Desktop execution is claimed. Initial and final failures are preserved in the evidence rather than hidden.

## AI disclosure and verification limits

ChatGPT (model/version not exposed) generated the code, prompt refinements, tests, calculations, explanatory text and reflection. The course's specific code-generation steps conflict with its general design-only/no-computation rules. This package discloses that conflict. The student must review the code, complete the required Sheets/independent/spot-check pattern and make the reflection their own before claiming personal verification. No human-authored correction or peer review is invented. See Appendix_AI.md.
