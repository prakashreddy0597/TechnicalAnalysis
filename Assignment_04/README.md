# Assignment 4 — Clean This Dataset with R and dplyr

Bhanu Rachamalla · BDA400 · 24 November 2026

## Inputs and schema

`data/sales_data_dirty.csv` is a transcription of the 610-row synthetic table supplied in the chat. Actual fields: OrderID, Product, Quantity, Price and Customer. CustomerID, Region and Revenue do not exist and are not created.

## Run

From this assignment folder:

```sh
Rscript install_packages.R
Rscript rachamalla_bhanu_clean_sales_data.R
```

Tested with R 4.4.3 and dplyr 1.2.1. The script reads with `read.csv()` and uses `mutate()`, `distinct()`, `count()`, `filter()` and `select()` in separately documented stages.

## Executed result

- 610 original records = 378 retained + 223 quarantined + 9 duplicate copies.
- Both conflicting versions of OrderID 265 are quarantined, not arbitrarily resolved.
- Retained records have no missing values in their supplied required fields and no duplicate OrderIDs.
- Product labels are Gadget, Thingamajig and Widget. All eight synthetic customer labels remain represented.
- No missing sales quantities are imputed. All original rows are traceable by SourceRow.
- A price of 300 is below the fitted price upper fence 314.445; three such prices remain. They need domain review, not an invented cap.

The positive-sales subset intentionally excludes nonpositive quantities, which might otherwise represent returns or cancellations. IQR screening is a documented demonstration choice, not an established company rule.

## Deliverables

- `rachamalla_bhanu_clean_sales_data.R`: final annotated script.
- `outputs/clean.csv`: reporting subset.
- `outputs/quarantine.csv`: unresolved/incomplete/flagged records with all audit flags.
- `outputs/duplicates.csv`: removed duplicate copies.
- `outputs/dispositions.csv`: one disposition for every original row.
- `outputs/before_after.csv` and `thresholds.csv`: exact comparison and fitted boundaries.
- `evidence/Before_After_Output.txt`: actual R summaries, glimpse, tables and error/output logs.
- `evidence/Independent_Check.json`: independent assistant-run Python row/quantile check.
- `evidence/Regression_Output.txt`: additional synthetic normalization and safety checks.
- `verification/Student_Verification.xlsx`: formulas for the student to recalculate in Sheets and record actual checks.
- `rachamalla_bhanu_reflection.txt`: explicitly AI-generated first-person draft, contrary to the brief's no-AI-reflection requirement; it is not represented as original student writing.
- `Rachamalla_Bhanu_CA_BDA400_A04.pdf`: review report. The assignment asks for a ZIP; a PDF alone is not the specified complete submission.

## AI disclosure

ChatGPT (model/version not exposed) generated code, performed calculations/checks and drafted documentation and reflection. Applied prompts, observed errors, user requests and policy limitations are in Appendix_AI.md. Independent student review, original student reflection and the required Sheets/peer-or-self checks are not claimed. The data and technical work are ready for review; those course requirements remain distinct from passing code tests.
