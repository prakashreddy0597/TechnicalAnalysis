> **AI Assistance Declaration:** ChatGPT (model/version not exposed), 24 November 2026, assisted with R code, cleaning-policy design, execution, calculations, documentation and a first-person reflection draft at the user's express request. Prompts and actual responses are recorded below. Assistant checks are not student manual verification. All final calculations are done by myself. I am responsible for the accuracy and originality of this work. Clarification: calculations were assistant-executed; the template sentence does not certify student calculation. The reflection is AI-generated, not independently authored by the student.

# Prompts and key responses

## Actual user request and data

The user supplied the full BDA400 Assignment 4 brief and a pasted table containing 610 synthetic records. The table was transcribed to `data/sales_data_dirty.csv`; no original CSV attachment was supplied. The first 600 OrderIDs are 1 through 600, followed by ten repeated IDs. Nine are exact repeated records; OrderID 265 has a different quantity in its later occurrence. The original pasted table should remain available for transcription checks.

The user then requested: “It’s okay you give like human I will review and go ahead”. In response, the assistant supplied a first-person reflection **draft**, with explicit AI authorship rather than pretending it was independently written by the student.

## Applied prompt sequence

These prompts instantiate the assignment instructions within one assistant workflow; they are not fabricated separately timestamped chat turns.

1. **Generic seed supplied in the brief:** “I have a sales dataset in R with missing customer IDs, inconsistent region names, and outliers in revenue. What are common data cleaning steps I should perform using dplyr?”
   - **Validation:** those fields do not exist in the pasted schema. A real trial of `filter(raw, !is.na(CustomerID))` produced an object-not-found error. The log retains that error. The workflow does not invent CustomerID, Region or Revenue.
2. **Schema refinement:** “Here are the actual columns OrderID, Product, Quantity, Price and Customer and the first ten rows. Suggest dplyr code for observed missing Product/Quantity values, duplicate rows, conflicting orders and numeric screening.”
   - **Response:** use the real schema; label missing values explicitly; preserve SourceRow; normalize existing text; do not generate identities or make up sales quantities.
3. **Duplicate critique:** “OrderID 265 occurs with Quantity 1000 and 25. Distinguish identical records from conflicting versions; do not arbitrarily keep one.”
   - **Response:** distinct on all five business fields, then quarantine every remaining version of a conflicting OrderID. SourceRow is excluded from distinctness or every record would appear unique.
4. **Policy refinement:** “Prepare a positive-sales reporting subset, preserve exclusions and define explicit statistical screening assumptions. Do not impute missing sales values or assume a universal price ceiling.”
   - **Response:** quarantine incomplete/nonpositive rows and fitted IQR flags. Use type-7 quartiles; Quantity outer fences use 3 IQR and Price uses 1.5 IQR. The rules are review choices, not verified company policy.
5. **Line explanation and verification:** “Explain the pipeline, simplify its stages, and confirm row reconciliation, missingness, duplicate handling and standardized categories.”
   - **Response:** validation, normalization, duplicate copies, conflicts, eligible threshold fitting, flagging, audited filtering and exports are separated. Every original row receives one disposition. Independent Python checks reproduce all 610 decisions.
6. **Result critique:** “Does a value of 300 have to be removed if it is below the fitted price fence? Explain any limitations.”
   - **Response:** no. The upper price fence is 314.445, so 300 is retained under this rule; three such prices occur in the clean subset. They warrant domain review, not a fabricated price cap or a forced statistical conclusion.

## Important interpretation limits

- The raw Product labels and customer casing are already consistent apart from missing Product values. Normalization is defensive; no nonexistent region or casing problem is invented.
- Customer names are synthetic labels, not authoritative CustomerIDs. No CustomerID completeness claim is made.
- The one-row-per-order assumption must be revisited if real orders can contain multiple line items.
- Nonpositive quantities may represent returns/cancellations. They are excluded from this **positive-sales reporting subset**, not declared universally erroneous.
- A complete-case subset can be biased. Zero missing values after exclusions does not mean missing original sales were recovered.
- Statistical flags are preserved for review; they are not proven mistakes. Quantities of 100 are retained while 1000 is excluded under the fitted quantity fence.
- Native R 4.4.3 with dplyr 1.2.1 executed in the managed workspace, not the student's personal RStudio Desktop.

## Remaining course-rule limitations

The specific steps request generated R code, while the general rules prohibit AI generation/computation. This package follows the requested technical workflow and discloses the conflict. Assistant-run R and Python validation is not the student's Sheets/independent/spot-check sequence.

The brief expressly says **not to use AI to write the reflection**. The user requested an AI draft anyway. Its inclusion is disclosed and does not satisfy that independent-writing requirement merely because the student later reviews it. No human code correction, original student reflection or completed student manual check is fabricated.

## References inspected 24 November 2026

- https://dplyr.tidyverse.org/reference/distinct.html
- https://dplyr.tidyverse.org/reference/filter.html
- https://dplyr.tidyverse.org/reference/mutate.html

The source documentation supports the selected verbs. `distinct()` retains the first row for the selected key, so an incomplete key can hide conflicting business records. `filter()` drops conditions that evaluate to NA, which is why missingness is flagged explicitly before selection.
