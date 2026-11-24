# AI-assisted workflow for BDA400 Assignment 2, 24 November 2026.
# Run from Assignment_02. Actual source is Yahoo Finance, not synthetic data.
source("scripts/stock_utilities.R")
args <- commandArgs(trailingOnly = TRUE)
data_source <- if (length(args)) args[[1L]] else "yahoo"
dir.create("outputs", showWarnings = FALSE)
stocks <- load_stock_data(source = data_source)
results <- lapply(names(stocks), function(symbol) calculate_statistics(stocks[[symbol]], symbol, window = 5L))
names(results) <- names(stocks)
summary_table <- do.call(rbind, lapply(results, `[[`, "summary"))
rownames(summary_table) <- NULL
utils::write.csv(summary_table, "outputs/statistics.csv", row.names = FALSE)
for (symbol in names(results)) {
  utils::write.csv(results[[symbol]]$series,
                   file.path("outputs", paste0(symbol, "_with_SMA.csv")), row.names = FALSE)
}
saveRDS(list(stocks = stocks, results = results, summary = summary_table,
             data_source = data_source, run_time_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)),
        "outputs/analysis.rds")
display_stock_data(stocks, results)
plot_stock_data(results)
cat("\n=== Combined statistics ===\n")
print(summary_table, row.names = FALSE)
cat("\n=== Software versions ===\n")
cat(R.version.string, "\n")
for (package in c("quantmod", "TTR", "xts", "zoo", "curl")) {
  cat(package, as.character(utils::packageVersion(package)), "\n")
}
cat("Source:", data_source, "| requested period: 2024-01-01 to 2024-03-31 inclusive\n")
