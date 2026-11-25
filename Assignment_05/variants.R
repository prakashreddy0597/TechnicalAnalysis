# BDA400 Assignment 5 — base-R implementation, 24 November 2026.
# AI-assisted by ChatGPT (model/version not exposed); user supplied the brief.
# No indicator package or fitted-model helper is used in this implementation.
# See CONVENTIONS.md for literal-pseudocode choices and known ambiguities.
# Standard/causal alternatives, separate from literal-pseudocode entry points.
rsi_wilder <- function(data, period) {
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

  rsi_core <- function(x, p, literal = TRUE) {
    n <- length(x); out <- rep(NA_real_, n)
    if (n <= p) return(out)
    delta <- x[-1L] - x[-n]
    gains <- rep(0, n - 1L); losses <- rep(0, n - 1L)
    gains[delta > 0] <- delta[delta > 0]
    losses[delta < 0] <- -delta[delta < 0]
    average_gain <- sum(gains[seq_len(p)]) / p
    average_loss <- sum(losses[seq_len(p)]) / p
    score <- function(gain, loss) {
      if (gain == 0 && loss == 0) return(50)
      if (loss == 0) return(100)
      100 - 100 / (1 + gain / loss)
    }
    if (!literal) out[p + 1L] <- score(average_gain, average_loss)
    first <- if (literal) p + 1L else p + 2L
    if (first <= n) for (i in seq.int(first, n)) {
      average_gain <- (average_gain * (p - 1L) + gains[i - 1L]) / p
      average_loss <- (average_loss * (p - 1L) + losses[i - 1L]) / p
      out[i] <- score(average_gain, average_loss)
    }
    out
  }

  check_data(data)
  period <- check_period(period)
  rsi_core(data, period, literal = FALSE)
}

crossover_logical <- function(arr1, arr2) crossover(arr1, arr2) == "Up"
crossunder_logical <- function(arr1, arr2) crossunder(arr1, arr2) == "True"

stoch_rsi_rolling <- function(data, period, k_period, d_period, normalization_period = period) {
  # This variant is loaded after the required scripts and rsi_wilder().
  if (!is.numeric(normalization_period) || is.complex(normalization_period) ||
      length(normalization_period) != 1L || is.na(normalization_period) ||
      !is.finite(normalization_period) || normalization_period < 1 ||
      normalization_period > .Machine$integer.max || normalization_period != floor(normalization_period))
    stop("normalization_period must be a positive integer.")
  for (p in list(k_period, d_period)) {
    if (!is.numeric(p) || is.complex(p) || length(p) != 1L || is.na(p) ||
        !is.finite(p) || p < 1 || p != floor(p) || p > .Machine$integer.max)
      stop("Smoothing periods must be positive integers.")
  }
  n <- length(data)
  values <- rsi_wilder(data, period)
  raw <- rep(NA_real_, n)
  if (normalization_period <= n) for (i in seq.int(normalization_period, n)) {
    window <- values[seq.int(i - normalization_period + 1L, i)]
    if (anyNA(window)) next
    low <- min(window); high <- max(window)
    if (high > low) raw[i] <- (values[i] - low) / (high - low)
  }
  # Public sma() intentionally shortens output; left-pad to restore dates here.
  k <- c(rep(NA_real_, k_period - 1L), sma(raw, k_period))
  d <- c(rep(NA_real_, d_period - 1L), sma(k, d_period))
  list(k_line = k, d_line = d)
}
