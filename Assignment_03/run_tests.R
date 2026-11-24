# AI Assistance Declaration: ChatGPT generated this synthetic verification code
# on 24 November 2026. Prompts and attribution: Appendix_AI.md.
# Assistant-executed tests are not student manual or Sheets verification.
source("Rachamalla_AI_RFunction_Assignment.R")
dir.create("evidence", showWarnings = FALSE)
cases <- list(
  obvious = c(10, 15, 999, 20, 25),
  missing = c(10, NA, 15, 999, NaN, 20, 25),
  no_outliers = c(10, 12, 14, 16, 18),
  hinge_difference = c(0, 1, 2, 3, 4, 8),
  negative_outlier = c(-999, 10, 12, 14, 16, 18, 20),
  constant = rep(5, 6),
  zero_iqr_outlier = c(5, 5, 5, 5, 100),
  boundaries = c(-3, 0, 0, 1, 1, 2, 2, 5),
  one_value = 42,
  empty = numeric(0),
  all_missing = c(NA_real_, NaN),
  named_order = c(a = 20, b = 999, c = 10, d = 25, e = 15)
)
outcomes <- list()
cat("VERSION 1: observed missing-value error\n")
tryCatch(print(remove_outliers_v1(c(10, NA, 15, 999, 20, 25))),
         error = function(e) cat("Observed error:", conditionMessage(e), "\n"))
cat("\nVERSION 2: differing quartile convention, not a calculation mistake\n")
example <- cases$hinge_difference
cat("Input:", example, "\n")
cat("V2 retained:", remove_outliers_v2(example), "\n")
cat("boxplot.stats outliers:", grDevices::boxplot.stats(example)$out, "\n")
cat("Final retained:", remove_outliers(example)$clean, "\n")
cat("\nFINAL: comparisons with boxplot.stats for supported inputs\n")
for (name in names(cases)) {
  x <- cases[[name]]
  actual <- remove_outliers(x)
  finite <- x[!is.na(x)]
  reference <- grDevices::boxplot.stats(finite, coef = 1.5, do.conf = FALSE)$out
  expected <- finite[!(finite %in% reference)]
  stopifnot(identical(actual$clean, expected))
  stopifnot(identical(unname(actual$removed), unname(reference)))
  stopifnot(actual$n_input == length(actual$clean) + actual$n_missing + actual$n_outliers)
  outcomes[[name]] <- data.frame(Case = name, Result = "PASS", Kind = "reference comparison")
  cat(name, "PASS | clean:", paste(actual$clean, collapse = ", "),
      "| outliers:", paste(actual$removed, collapse = ", "),
      "| missing:", actual$n_missing, "\n")
}
# Explicit expectations are independent of boxplot.stats implementation details.
stopifnot(identical(remove_outliers(cases$obvious)$clean, c(10, 15, 20, 25)))
stopifnot(identical(remove_outliers(cases$missing)$missing_positions, c(2L, 5L)))
stopifnot(identical(remove_outliers(cases$boundaries)$clean, cases$boundaries))
stopifnot(identical(remove_outliers(cases$named_order)$outlier_positions, 2L))
stopifnot(identical(remove_outliers(cases$hinge_difference)$clean, cases$hinge_difference))
stopifnot(identical(remove_outliers(1:5)$clean, 1:5))
cat("Explicit expected values, boundary inclusion, positions and integer type: PASS\n")
invalid <- list(
  character = function() remove_outliers(c("10", "20")),
  logical = function() remove_outliers(c(TRUE, FALSE)),
  matrix = function() remove_outliers(matrix(1:4, 2)),
  factor = function() remove_outliers(factor(c(1, 2))),
  complex = function() remove_outliers(c(1+1i, 2+0i)),
  null = function() remove_outliers(NULL),
  infinity = function() remove_outliers(c(1, Inf)),
  coefficient_zero = function() remove_outliers(1:5, coef = 0),
  coefficient_missing = function() remove_outliers(1:5, coef = NA_real_),
  coefficient_vector = function() remove_outliers(1:5, coef = c(1, 2)),
  coefficient_complex = function() remove_outliers(1:5, coef = 1+1i),
  invalid_na_policy = function() remove_outliers(1:5, na.rm = NA),
  missing_forbidden = function() remove_outliers(c(1, NA), na.rm = FALSE),
  overflow = function() remove_outliers(c(-1e308, 0, 1e308))
)
cat("\nFINAL: invalid input / deliberate policy rejections\n")
for (name in names(invalid)) {
  message <- tryCatch({invalid[[name]](); NA_character_}, error = conditionMessage)
  stopifnot(!is.na(message))
  outcomes[[name]] <- data.frame(Case = name, Result = "PASS", Kind = "expected rejection")
  cat(name, "PASS | expected error:", message, "\n")
}
custom <- remove_outliers(cases$obvious, coef = 3)
stopifnot(identical(custom$removed, grDevices::boxplot.stats(cases$obvious, coef = 3)$out))
cat("Custom positive coefficient comparison: PASS\n")
table <- do.call(rbind, outcomes)
utils::write.csv(table, "evidence/test_summary.csv", row.names = FALSE)
saveRDS(lapply(cases, remove_outliers), "evidence/test_results.rds")
cat("\nR session:\n")
print(sessionInfo())
cat("\nAll assertions completed successfully.\n")
