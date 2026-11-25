# BDA400 Assignment 5 — base-R implementation, 24 November 2026.
# AI-assisted by ChatGPT (model/version not exposed); user supplied the brief.
# No indicator package or fitted-model helper is used in this implementation.
# See CONVENTIONS.md for literal-pseudocode choices and known ambiguities.
macd <- function(data, short_period, long_period, signal_period) {
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

  ema_core <- function(x, p) {
    n <- length(x); out <- numeric(n)
    if (n == 0L) return(out)
    multiplier <- 2 / (p + 1)
    out[1L] <- x[1L]
    if (n >= 2L) for (i in seq.int(2L, n))
      out[i] <- (x[i] - out[i - 1L]) * multiplier + out[i - 1L]
    out
  }

  check_data(data)
  short_period <- check_period(short_period, "short_period")
  long_period <- check_period(long_period, "long_period")
  signal_period <- check_period(signal_period, "signal_period")
  short_ema <- ema_core(data, short_period)
  long_ema <- ema_core(data, long_period)
  macd_line <- short_ema - long_ema
  signal_line <- ema_core(macd_line, signal_period)
  histogram <- macd_line - signal_line
  result <- list(macd_line = macd_line, signal_line = signal_line, histogram = histogram)
  return(result)
}
