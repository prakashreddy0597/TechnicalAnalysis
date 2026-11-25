# BDA400 Assignment 5 — base-R implementation, 24 November 2026.
# AI-assisted by ChatGPT (model/version not exposed); user supplied the brief.
# No indicator package or fitted-model helper is used in this implementation.
# See CONVENTIONS.md for literal-pseudocode choices and known ambiguities.
rsi <- function(data, period) {
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
  # Literal loop repeats the period-th change when forming the first RSI.
  # rsi_wilder() in variants.R supplies the standard seeded alternative.
  rsi_values <- rsi_core(data, period, literal = TRUE)
  return(rsi_values)
}
