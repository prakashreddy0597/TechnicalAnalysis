# BDA400 Assignment 5 — base-R implementation, 24 November 2026.
# AI-assisted by ChatGPT (model/version not exposed); user supplied the brief.
# No indicator package or fitted-model helper is used in this implementation.
# See CONVENTIONS.md for literal-pseudocode choices and known ambiguities.
sma <- function(data, period) {
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

  sma_core <- function(x, p) {
    n <- length(x)
    if (n < p) stop("Data length should be greater than or equal to the period", call. = FALSE)
    out <- rep(NA_real_, n - p + 1L)
    for (i in seq_along(out)) {
      window <- x[seq.int(i, i + p - 1L)]
      if (!anyNA(window)) out[i] <- sum(window) / p
    }
    out
  }

  check_data(data, allow_na = TRUE)
  period <- check_period(period)
  sma_values <- sma_core(data, period)
  return(sma_values)
}
