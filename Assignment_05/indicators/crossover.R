# BDA400 Assignment 5 — base-R implementation, 24 November 2026.
# AI-assisted by ChatGPT (model/version not exposed); user supplied the brief.
# No indicator package or fitted-model helper is used in this implementation.
# See CONVENTIONS.md for literal-pseudocode choices and known ambiguities.
crossover <- function(arr1, arr2) {
  check_data <- function(x, allow_na = FALSE, allow_empty = TRUE) {
    if (!is.numeric(x) || is.complex(x) || is.object(x) || !is.null(dim(x)))
      stop("Data must be a plain real numeric vector.", call. = FALSE)
    if (!allow_empty && length(x) == 0L) stop("Data must not be empty.", call. = FALSE)
    if (any(is.infinite(x)) || (!allow_na && anyNA(x)))
      stop("Data contain unsupported missing or infinite values.", call. = FALSE)
  }
  check_period <- function(p, label = "period") {
    if (!is.numeric(p) || is.complex(p) || length(p) != 1L ||
        is.na(p) || !is.finite(p) || p < 1 || p != floor(p) || p > .Machine$integer.max)
      stop(paste(label, "must be a positive integer."), call. = FALSE)
    as.integer(p)
  }

  check_data(arr1, allow_na = TRUE); check_data(arr2, allow_na = TRUE)
  if (length(arr1) != length(arr2)) stop("Both arrays should have the same length", call. = FALSE)
  n <- length(arr1)
  crossover_signals <- rep("None", n)
  if (n >= 2L) for (i in seq.int(2L, n)) {
    if (anyNA(c(arr1[i], arr2[i], arr1[i - 1L], arr2[i - 1L]))) next
    if (arr1[i] > arr2[i] && arr1[i - 1L] <= arr2[i - 1L]) {
      crossover_signals[i] <- "Up"
    } else if (arr1[i] < arr2[i] && arr1[i - 1L] >= arr2[i - 1L]) {
      crossover_signals[i] <- "Down"
    }
  }
  return(crossover_signals)
}
