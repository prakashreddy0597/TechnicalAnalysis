# BDA400 Assignment 5 — base-R implementation, 24 November 2026.
# AI-assisted by ChatGPT (model/version not exposed); user supplied the brief.
# No indicator package or fitted-model helper is used in this implementation.
# See CONVENTIONS.md for literal-pseudocode choices and known ambiguities.
linreg <- function(regressionSource, regressionLength, regressionOffset) {
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

  check_data(regressionSource, allow_empty = FALSE)
  regressionLength <- check_period(regressionLength, "regressionLength")
  n <- length(regressionSource)
  if (regressionLength > n)
    stop("regressionLength cannot be greater than the number of elements in regressionSource", call. = FALSE)
  if (!is.numeric(regressionOffset) || is.complex(regressionOffset) ||
      length(regressionOffset) != 1L || is.na(regressionOffset) ||
      !is.finite(regressionOffset) || regressionOffset < 0 || regressionOffset != floor(regressionOffset))
    stop("regressionOffset must be a non-negative integer.", call. = FALSE)
  if (regressionOffset >= regressionLength)
    stop("regressionOffset must be less than regressionLength", call. = FALSE)
  # Literal supplied indices; notably offset zero can select Length + 1 points.
  start_index <- max(1L, n - regressionLength + regressionOffset)
  end_index <- min(n, n - regressionOffset)
  if (start_index > end_index) stop("The supplied indices produce an empty regression window.", call. = FALSE)
  source_subset <- regressionSource[seq.int(start_index, end_index)]
  m <- length(source_subset)
  if (m < 2L) stop("At least two points are required for regression.", call. = FALSE)
  index_values <- seq_len(m)
  mean_index <- sum(index_values) / m
  mean_source <- sum(source_subset) / m
  numerator <- sum((index_values - mean_index) * (source_subset - mean_source))
  denominator <- sum((index_values - mean_index)^2)
  slope <- numerator / denominator
  intercept <- mean_source - slope * mean_index
  predicted_values <- slope * index_values + intercept
  result <- list(slope = slope, intercept = intercept, predicted_values = predicted_values)
  return(result)
}
