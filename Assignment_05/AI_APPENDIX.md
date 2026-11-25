# AI attribution and development record

Tool: ChatGPT. Exact backend model/version was not exposed. Date: 24 November 2026. Scope: AI-assisted base-R code, validation code, execution, documentation and report preparation. Native R and an independent Python reference generated the actual evidence files.

## User prompt

The user supplied the complete Assignment 5 brief, “Technical Analysis using R, Development Phase (15%)”, including the nine function signatures, formulas and pseudocode, repository requirement, implementation explanations and submission cover instructions. Earlier requests established AAPL, MSFT and GOOGL and authorized work in the public TechnicalAnalysis repository.

## Clarification raised by the assistant

“Do you have the instructor’s test file or any clarification about the conflicting output conventions? If not, I’ll preserve the supplied function signatures, document chosen conventions, and keep standard financial variants separate.”

No instructor test or clarification was available when this package was prepared. This is a record of the actual exchange, not a fabricated sequence of student prompts.

## Key response and implementation decisions

- Preserve required signatures in separate scripts, using no contributed indicator library.
- Follow literal supplied pseudocode for primary outputs and explicitly describe its nonstandard behavior.
- Keep standard Wilder RSI, rolling StochRSI and Boolean crossover adapters separately named.
- Test calculations, input guards, output shapes, date alignment and standalone sourceability.
- Reuse frozen provider CSVs and use Close consistently in Assignment 5.
- Generate candidate trading signals without using globally normalized StochRSI or assuming same-close execution.

## Validation and limitations

The package contains genuine R output, 65 R checks and 51 independent Python series/aggregation checks. The reference `lm()` and `sd()` are used only in tests, never inside indicator implementations. Python is an optional independent reference. No human review, peer sign-off, instructor test pass, personal-PC execution or profitable trading result is invented.
