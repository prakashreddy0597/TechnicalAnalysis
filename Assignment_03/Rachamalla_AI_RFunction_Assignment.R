# AI Assistance Declaration: I used ChatGPT (model/version not exposed),
# 24 November 2026, for prompts, example code, comments and debugging assistance.
# Prompts: see Appendix_AI.md. Assistant-run verification is in evidence/.
# Independent student manual/Sheets verification has not been claimed.
# All final calculations are done by myself. I am responsible for the accuracy
# and originality of this work. Clarification: calculations in the supplied
# evidence were actually performed by assistant-executed R; the template's
# calculations sentence must not be interpreted as a claim of student work.
# All code and explanatory comments below are AI-generated.
#
# Original one-sentence task:
# Remove unusually low or high observations from a numeric vector using
# 1.5-IQR outlier fences, while retaining the original order of the values.
#
# Final specification after refinement:
# Use Tukey hinges, matching boxplot.stats() for supported finite data and a
# positive coefficient; remove NA/NaN by default, reject infinities, preserve
# names/order, and return both the clean vector and an audit of exclusions.
# Base R only. Do not use on real personal data; test inputs are synthetic.

# VERSION 1 — initial seed response, retained to show the starting point.
remove_outliers_v1 <- function(x) {                       # Define the initial function.
  q <- stats::quantile(x, c(0.25, 0.75))                   # Calculate default type-7 quartiles.
  spread <- q[2L] - q[1L]                                # Calculate the interquartile span.
  lower <- q[1L] - 1.5 * spread                          # Construct the lower fence.
  upper <- q[2L] + 1.5 * spread                          # Construct the upper fence.
  x[x >= lower & x <= upper]                             # Keep values inside inclusive fences.
}                                                       # Finish the initial function.

# VERSION 2 — missing-value/validation refinement; type-7 convention remains.
remove_outliers_v2 <- function(x) {                       # Define an intermediate refinement.
  if (!is.numeric(x) || is.complex(x) || !is.null(dim(x))) { # Require a real numeric vector.
    stop("x must be a real numeric vector.")             # Explain an invalid argument.
  }                                                     # Finish input-type validation.
  x <- x[!is.na(x)]                                      # Drop missing NA/NaN entries.
  if (any(!is.finite(x))) {                              # Detect unsupported infinite values.
    stop("x must not contain infinite values.")          # Reject infinities rather than ignore them.
  }                                                     # Finish the infinity guard.
  if (!length(x)) return(x)                              # Handle empty/all-missing input.
  q <- stats::quantile(x, c(0.25, 0.75), names = FALSE)    # Retain default type-7 quartiles.
  spread <- q[2L] - q[1L]                                # Calculate the quartile span once.
  x[x >= q[1L] - 1.5 * spread & x <= q[2L] + 1.5 * spread] # Filter while retaining order.
}                                                       # Finish the intermediate version.

# VERSION 3 — final function; every executable line is explained in a comment.
remove_outliers <- function(x, coef = 1.5, na.rm = TRUE) { # Define inputs and documented defaults.
  if (!is.numeric(x) || is.complex(x) || is.object(x) || !is.null(dim(x))) { # Reject unsupported types/classes.
    stop("x must be a plain real numeric vector.", call. = FALSE) # Give a readable type error.
  }                                                     # Complete vector validation.
  if (!is.numeric(coef) || is.complex(coef) || is.object(coef) || length(coef) != 1L) { # Validate coefficient type/size.
    stop("coef must be one finite positive number.", call. = FALSE) # Reject malformed coefficients.
  }                                                     # Finish coefficient type validation.
  if (is.na(coef) || !is.finite(coef) || coef <= 0) {      # Require a finite strictly positive coefficient.
    stop("coef must be one finite positive number.", call. = FALSE) # Explain the coefficient policy.
  }                                                     # Finish coefficient range validation.
  if (!is.logical(na.rm) || length(na.rm) != 1L || is.na(na.rm)) { # Require a scalar logical missing policy.
    stop("na.rm must be TRUE or FALSE.", call. = FALSE)   # Reject ambiguous missing-value settings.
  }                                                     # Finish missing-policy validation.
  missing <- is.na(x)                                    # Mark both NA and NaN values.
  if (any(missing) && !na.rm) {                          # Honor a caller who forbids omission.
    stop("Missing values present; set na.rm = TRUE to omit them.", call. = FALSE) # Fail explicitly.
  }                                                     # Finish the missing-value policy check.
  if (any(is.infinite(x))) {                             # Detect either sign of infinity.
    stop("x must not contain infinite values.", call. = FALSE) # Keep supported inputs finite.
  }                                                     # Finish the infinity guard.
  valid_positions <- unname(which(!missing))             # Retain original integer indices without inherited labels.
  values <- x[valid_positions]                           # Select usable values without sorting the output.
  hinges <- c(NA_real_, NA_real_)                         # Define an empty-input summary consistently.
  lower <- NA_real_                                      # Leave an undefined lower fence for no data.
  upper <- NA_real_                                      # Leave an undefined upper fence for no data.
  keep <- logical(length(values))                        # Allocate a mask of the appropriate length.
  if (length(values)) {                                  # Compute fences only when observations exist.
    five <- stats::fivenum(values, na.rm = FALSE)          # Obtain Tukey's five-number summary.
    hinges <- unname(five[c(2L, 4L)])                     # Extract lower and upper hinges.
    spread <- hinges[2L] - hinges[1L]                    # Calculate the hinge-based IQR.
    lower <- hinges[1L] - coef * spread                  # Compute the lower inclusive boundary.
    upper <- hinges[2L] + coef * spread                  # Compute the upper inclusive boundary.
    if (any(!is.finite(c(spread, lower, upper)))) {        # Detect floating-point overflow.
      stop("Non-finite fences; rescale x or reduce coef.", call. = FALSE) # Avoid silent overflow decisions.
    }                                                   # Finish the numerical-range guard.
    keep <- values >= lower & values <= upper            # Keep exact-boundary observations.
  }                                                     # Finish fence construction and filtering.
  kept_positions <- valid_positions[keep]                # Map retained values to original indices.
  outlier_positions <- valid_positions[!keep]            # Map excluded outliers separately from missing values.
  list(                                                 # Return a structured, auditable result.
    clean = x[kept_positions],                           # Preserve the retained values' order and names.
    removed = x[outlier_positions],                      # Preserve excluded outliers, including duplicates.
    kept_positions = kept_positions,                     # Report retained original positions.
    outlier_positions = outlier_positions,               # Report outlier original positions.
    missing_positions = unname(which(missing)),          # Report plain integer indices of missing entries.
    lower_hinge = hinges[1L],                            # Make the lower hinge inspectable.
    upper_hinge = hinges[2L],                            # Make the upper hinge inspectable.
    lower_fence = lower,                                 # Expose the lower decision boundary.
    upper_fence = upper,                                 # Expose the upper decision boundary.
    n_input = length(x),                                 # Report the original vector size.
    n_missing = sum(missing),                            # Count omitted missing entries.
    n_outliers = length(outlier_positions),               # Count outliers without mixing in missing entries.
    coef = coef,                                        # Record the coefficient actually used.
    method = "Tukey hinges; inclusive fences"             # Record the statistical convention.
  )                                                     # Finish the result object.
}                                                       # Finish the final function.

# Usage example (run explicitly in R/RStudio; sourcing only defines functions):
# example <- remove_outliers(c(10, 15, 999, 20, 25, NA_real_))
# example$clean
# example$outlier_positions
# Run the complete verification from this folder using:
# Rscript run_tests.R
