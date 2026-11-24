# AI-assisted code by ChatGPT (model/version not exposed), 24 November 2026.
# Purpose: implement the attached BDA400 Assignment 2 preliminary analysis.
# No trading recommendations. Actual execution and evidence are reported separately.

load_stock_data <- function(portfolio_file = "portfolio.txt",
                            start_date = "2024-01-01", end_date = "2024-03-31",
                            source = c("yahoo", "cache"), data_dir = "data") {
  source <- match.arg(source)
  if (!file.exists(portfolio_file)) stop("Portfolio file not found: ", portfolio_file)
  symbols <- trimws(readLines(portfolio_file, warn = FALSE))
  symbols <- unique(symbols[nzchar(symbols)])
  if (!length(symbols) || any(!grepl("^[A-Z0-9.^=-]+$", symbols))) {
    stop("Portfolio must contain valid uppercase symbols, one per line.")
  }
  start_date <- as.Date(start_date); end_date <- as.Date(end_date)
  if (is.na(start_date) || is.na(end_date) || start_date > end_date) {
    stop("Invalid date range.")
  }
  dir.create(data_dir, showWarnings = FALSE, recursive = TRUE)
  frames <- setNames(vector("list", length(symbols)), symbols)
  for (symbol in symbols) {
    path <- file.path(data_dir, paste0(symbol, ".csv"))
    if (source == "yahoo") {
      options <- list()
      if (file.exists("/etc/ssl/certs/ca-certificates.crt")) {
        options$cainfo <- "/etc/ssl/certs/ca-certificates.crt"
      }
      raw <- tryCatch(
        quantmod::getSymbols(symbol, src = "yahoo", from = start_date,
                             to = end_date + 1, auto.assign = FALSE,
                             curl.options = options),
        error = function(e) stop("Import failed for ", symbol, ": ", conditionMessage(e))
      )
      frame <- data.frame(
        Date = as.Date(zoo::index(raw)),
        Open = as.numeric(quantmod::Op(raw)),
        High = as.numeric(quantmod::Hi(raw)),
        Low = as.numeric(quantmod::Lo(raw)),
        Close = as.numeric(quantmod::Cl(raw)),
        Volume = as.numeric(quantmod::Vo(raw)),
        Adjusted = as.numeric(quantmod::Ad(raw))
      )
      frame <- frame[frame$Date >= start_date & frame$Date <= end_date, ]
      utils::write.csv(frame, path, row.names = FALSE)
    } else {
      if (!file.exists(path)) stop("Cached file not found: ", path)
      frame <- utils::read.csv(path, stringsAsFactors = FALSE)
      frame$Date <- as.Date(frame$Date)
      frame <- frame[frame$Date >= start_date & frame$Date <= end_date, ]
    }
    expected <- c("Date", "Open", "High", "Low", "Close", "Volume", "Adjusted")
    if (!identical(names(frame), expected) || !nrow(frame)) stop("Invalid or empty data: ", symbol)
    if (anyNA(frame$Date) || anyDuplicated(frame$Date)) stop("Invalid/duplicate dates: ", symbol)
    frame <- frame[order(frame$Date), ]
    rownames(frame) <- NULL
    frames[[symbol]] <- frame
  }
  frames
}

calculate_statistics <- function(stock_frame, symbol, window = 5L) {
  if (!all(c("Date", "Adjusted") %in% names(stock_frame))) stop("Missing price columns.")
  if (length(window) != 1L || !is.numeric(window) || is.na(window) ||
      window < 1L || window != as.integer(window)) stop("Window must be a positive integer.")
  valid <- is.finite(stock_frame$Adjusted)
  clean <- stock_frame[valid, ]
  price <- clean$Adjusted
  if (length(price) < max(2L, window)) stop("Insufficient valid observations for ", symbol)
  # This is a trailing window over complete observed trading sessions, not calendar days.
  clean$SMA5 <- as.numeric(TTR::SMA(price, n = window))
  values <- unique(price)
  frequencies <- tabulate(match(price, values))
  maximum <- max(frequencies)
  modes <- if (maximum > 1L) sort(values[frequencies == maximum]) else numeric(0)
  mode_text <- if (!length(modes)) {
    "No unique mode: all values occur once"
  } else {
    paste(format(modes, digits = 10L, trim = TRUE), collapse = "; ")
  }
  summary <- data.frame(
    Symbol = symbol, Observations = length(price),
    MissingAdjustedRows = sum(!valid),
    FirstDate = as.character(min(clean$Date)), LastDate = as.character(max(clean$Date)),
    Mean = mean(price), Median = stats::median(price), Mode = mode_text,
    ModeFrequency = maximum, SampleSD = stats::sd(price),
    SMAWindow = window, LatestSMA = tail(clean$SMA5, 1L),
    stringsAsFactors = FALSE
  )
  # Independent arithmetic identities guard against accidental wrong-column/window use.
  stopifnot(isTRUE(all.equal(mean(price), sum(price) / length(price))))
  stopifnot(isTRUE(all.equal(tail(clean$SMA5, 1L), mean(tail(price, window)), tolerance = 1e-10)))
  list(summary = summary, series = clean, mode_values = modes)
}

display_stock_data <- function(stock_frames, results, rows = 5L) {
  for (symbol in names(stock_frames)) {
    cat("\n=== ", symbol, ": imported OHLCV data ===\n", sep = "")
    print(utils::head(stock_frames[[symbol]], rows), row.names = FALSE)
    cat("Rows:", nrow(stock_frames[[symbol]]), "\n")
    cat("Summary based on adjusted closing price (USD):\n")
    print(results[[symbol]]$summary, row.names = FALSE)
    cat("Trailing SMA observations (last rows):\n")
    print(utils::tail(results[[symbol]]$series[, c("Date", "Adjusted", "SMA5")], rows), row.names = FALSE)
  }
  invisible(NULL)
}

plot_stock_data <- function(results, output_dir = "outputs") {
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)
  for (symbol in names(results)) {
    series <- results[[symbol]]$series
    grDevices::png(file.path(output_dir, paste0(symbol, "_adjusted_SMA.png")),
                   width = 1400, height = 850, res = 150)
    tryCatch({
      graphics::par(mar = c(5, 5, 4, 2))
      graphics::plot(series$Date, series$Adjusted, type = "l", lwd = 2,
                     col = "#174D68", xlab = "Trading date", ylab = "Adjusted close (USD)",
                     main = paste(symbol, "adjusted close and trailing", results[[symbol]]$summary$SMAWindow, "session SMA"))
      graphics::lines(series$Date, series$SMA5, col = "#C76B14", lwd = 2)
      graphics::legend("topleft", legend = c("Adjusted close", "Trailing SMA"),
                       col = c("#174D68", "#C76B14"), lty = 1, lwd = 2, bty = "n")
      graphics::grid(col = "#E1E6E8")
    }, finally = grDevices::dev.off())
  }
  invisible(NULL)
}
