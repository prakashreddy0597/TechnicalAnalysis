# AI Assistance Declaration: ChatGPT (model/version not exposed), 24 November
# 2026, assisted with code, debugging and assistant-executed calculations.
# Prompts and key responses: Appendix_AI.md. Student manual verification is
# not claimed. All final calculations are done by myself. I am responsible
# for the accuracy and originality of this work. Clarification: delivered
# calculations were actually performed by assistant-executed R.
# The reflection is intentionally not written by AI, as explicitly required.
#
# Actual schema: OrderID, Product, Quantity, Price, Customer.
# CustomerID, Region and Revenue are NOT present and are never invented.
# Policy: prepare a positive-sales reporting subset, retaining every excluded
# record in an audit. One row is assumed to represent one order. Returns,
# incomplete orders and statistical flags require review, not silent deletion.
# P1 (generic seed): suggest dplyr cleaning for missing IDs, region labels and
# revenue outliers. P2: adapt to the actual five-column schema and first 10 rows.
# P3: distinguish duplicate records from conflicting OrderID values.
# P4: preserve row provenance, explain each step, and verify reconciliation.

clean_sales_data <- function(data, quantity_multiplier = 3, price_multiplier = 1.5) {
  required <- c("OrderID", "Product", "Quantity", "Price", "Customer")
  if (!is.data.frame(data) || !all(required %in% names(data))) {
    stop("Input must contain OrderID, Product, Quantity, Price, Customer.", call. = FALSE)
  }
  if (!nrow(data)) stop("Input has no records.", call. = FALSE)
  if (!all(vapply(data[c("OrderID", "Quantity", "Price")], is.numeric, logical(1)))) {
    stop("OrderID, Quantity and Price must be numeric; inspect import errors.", call. = FALSE)
  }
  valid_multiplier <- function(x) is.numeric(x) && !is.complex(x) &&
    length(x) == 1L && !is.na(x) && is.finite(x) && x > 0
  if (!valid_multiplier(quantity_multiplier) || !valid_multiplier(price_multiplier)) {
    stop("Outlier multipliers must be finite positive scalars.", call. = FALSE)
  }
  # Tag the original row before any filtering. Do not overwrite the raw input.
  tagged <- data |>
    dplyr::select(dplyr::all_of(required)) |>
    dplyr::mutate(SourceRow = dplyr::row_number(),
      Product = dplyr::na_if(trimws(as.character(Product)), ""),
      Customer = dplyr::na_if(tolower(trimws(as.character(Customer))), "")) |>
    dplyr::mutate(Product = dplyr::case_when(
      tolower(Product) == "widget" ~ "Widget",
      tolower(Product) == "gadget" ~ "Gadget",
      tolower(Product) == "thingamajig" ~ "Thingamajig",
      is.na(Product) ~ NA_character_,
      TRUE ~ Product))
  # Compare business fields only; SourceRow would otherwise make all rows unique.
  unique_rows <- tagged |>
    dplyr::distinct(OrderID, Product, Quantity, Price, Customer, .keep_all = TRUE)
  duplicates <- tagged |>
    dplyr::filter(!SourceRow %in% unique_rows$SourceRow) |>
    dplyr::mutate(Disposition = "duplicate_record")
  # Multiple remaining versions of one ID are unresolved; never choose one by order.
  conflict_ids <- unique_rows |>
    dplyr::count(OrderID, name = "versions") |>
    dplyr::filter(!is.na(OrderID), versions > 1L) |>
    dplyr::pull(OrderID)
  flagged <- unique_rows |>
    dplyr::mutate(
      invalid_id = is.na(OrderID) | !is.finite(OrderID) | OrderID <= 0 | OrderID != floor(OrderID),
      conflicting_id = OrderID %in% conflict_ids,
      missing_customer = is.na(Customer),
      missing_product = is.na(Product),
      unknown_product = !is.na(Product) & !Product %in% c("Widget", "Gadget", "Thingamajig"),
      missing_quantity = is.na(Quantity),
      invalid_quantity = !is.na(Quantity) & (!is.finite(Quantity) | Quantity <= 0 | Quantity != floor(Quantity)),
      invalid_price = is.na(Price) | !is.finite(Price) | Price <= 0)
  # Fit fences once to complete, valid, nonconflicting records; no imputation.
  candidates <- flagged |>
    dplyr::filter(!invalid_id, !conflicting_id, !missing_customer,
                  !missing_product, !unknown_product, !missing_quantity,
                  !invalid_quantity, !invalid_price)
  if (nrow(candidates) < 4L) stop("Need at least four eligible records to fit fences.")
  q_quantity <- stats::quantile(candidates$Quantity, c(0.25, 0.75), names = FALSE, type = 7)
  q_price <- stats::quantile(candidates$Price, c(0.25, 0.75), names = FALSE, type = 7)
  quantity_fences <- q_quantity + c(-1, 1) * quantity_multiplier * diff(q_quantity)
  price_fences <- q_price + c(-1, 1) * price_multiplier * diff(q_price)
  if (any(!is.finite(c(quantity_fences, price_fences)))) stop("Non-finite fences; inspect scale.")
  # These are review screens, not established company validity rules.
  audit <- flagged |>
    dplyr::mutate(
      quantity_outlier = !is.na(Quantity) & is.finite(Quantity) &
        (Quantity < quantity_fences[1L] | Quantity > quantity_fences[2L]),
      price_outlier = !is.na(Price) & is.finite(Price) &
        (Price < price_fences[1L] | Price > price_fences[2L]),
      Disposition = dplyr::case_when(
        invalid_id ~ "invalid_order_id",
        conflicting_id ~ "conflicting_order_id",
        missing_customer ~ "missing_customer",
        missing_product ~ "missing_product",
        unknown_product ~ "unknown_product",
        missing_quantity ~ "missing_quantity",
        invalid_quantity ~ "nonpositive_or_invalid_quantity",
        invalid_price ~ "invalid_price",
        quantity_outlier ~ "quantity_outlier_review",
        price_outlier ~ "price_outlier_review",
        TRUE ~ "retained"))
  # Keep all boolean flags as well as one primary, mutually exclusive reason.
  clean <- audit |>
    dplyr::filter(Disposition == "retained") |>
    dplyr::select(SourceRow, dplyr::all_of(required))
  quarantine <- audit |> dplyr::filter(Disposition != "retained")
  dispositions <- dplyr::bind_rows(
    audit |> dplyr::select(SourceRow, OrderID, Disposition),
    duplicates |> dplyr::select(SourceRow, OrderID, Disposition)) |>
    dplyr::arrange(SourceRow)
  # Reconcile every original row exactly once, including duplicate copies.
  stopifnot(nrow(data) == nrow(clean) + nrow(quarantine) + nrow(duplicates),
            identical(dispositions$SourceRow, seq_len(nrow(data))),
            !anyDuplicated(clean$OrderID), !anyNA(clean),
            all(clean$Quantity > 0), all(clean$Quantity == floor(clean$Quantity)),
            all(clean$Price > 0),
            all(clean$Product %in% c("Widget", "Gadget", "Thingamajig")))
  list(clean = clean, quarantine = quarantine, duplicates = duplicates,
       audit = audit, dispositions = dispositions, conflict_ids = conflict_ids,
       thresholds = data.frame(
         Field = c("Quantity", "Price"), Q1 = c(q_quantity[1L], q_price[1L]),
         Q3 = c(q_quantity[2L], q_price[2L]),
         Multiplier = c(quantity_multiplier, price_multiplier),
         Lower = c(quantity_fences[1L], price_fences[1L]),
         Upper = c(quantity_fences[2L], price_fences[2L]),
         EligibleRows = nrow(candidates)))
}

# Source this file to define the function, or run it directly to execute the workflow.
if (sys.nframe() == 0L) {
  if (!requireNamespace("dplyr", quietly = TRUE)) stop("Install dplyr first.")
  dir.create("outputs", showWarnings = FALSE)
  dir.create("evidence", showWarnings = FALSE)
  raw <- utils::read.csv("data/sales_data_dirty.csv", stringsAsFactors = FALSE,
                         na.strings = c("", "NA"), check.names = FALSE)
  cat("ACTUAL SCHEMA\n"); print(names(raw))
  cat("\nBEFORE: summary(), glimpse(), categorical tables\n")
  print(summary(raw)); dplyr::glimpse(raw)
  print(table(raw$Product, useNA = "ifany")); print(table(raw$Customer, useNA = "ifany"))
  cat("Raw missing values by column:\n"); print(colSums(is.na(raw)))
  cat("Raw exact duplicate rows:", sum(duplicated(raw)), "\n")
  cat("Repeated ID values:", sum(duplicated(raw$OrderID)), "\n")
  cat("Raw zero quantities:", sum(raw$Quantity == 0, na.rm = TRUE), "\n")
  cat("Raw negative quantities:", sum(raw$Quantity < 0, na.rm = TRUE), "\n")
  # Reproduce the generic prompt's actual schema mismatch without fabricating an error.
  cat("\nGENERIC SUGGESTION CHECK\n")
  tryCatch(dplyr::filter(raw, !is.na(CustomerID)),
    error = function(e) cat("Observed schema error:", conditionMessage(e), "\n"))
  cat("\nFINAL PIPELINE\n")
  result <- clean_sales_data(raw)
  cat("Conflict IDs:\n"); print(result$conflict_ids)
  cat("Frozen screening thresholds:\n"); print(result$thresholds, row.names = FALSE)
  cat("Mutually exclusive row dispositions:\n"); print(table(result$dispositions$Disposition))
  cat("\nAFTER: summary(), glimpse(), categorical tables\n")
  print(summary(result$clean)); dplyr::glimpse(result$clean)
  print(table(result$clean$Product, useNA = "ifany")); print(table(result$clean$Customer, useNA = "ifany"))
  cat("Clean missing values by column:\n"); print(colSums(is.na(result$clean)))
  cat("Clean duplicate IDs:", sum(duplicated(result$clean$OrderID)), "\n")
  print(result$quarantine |> dplyr::filter(OrderID == 265) |>
          dplyr::select(SourceRow, OrderID, Quantity, Price, Customer, Disposition))
  for (name in c("clean", "quarantine", "duplicates", "audit", "dispositions", "thresholds")) {
    utils::write.csv(result[[name]], file.path("outputs", paste0(name, ".csv")), row.names = FALSE)
  }
  metrics <- data.frame(
    Metric = c("Rows", "Missing Product", "Missing Quantity", "Missing Customer", "Exact duplicate copies", "Repeated OrderID copies"),
    Before = c(nrow(raw), sum(is.na(raw$Product)), sum(is.na(raw$Quantity)),
               sum(is.na(raw$Customer)), sum(duplicated(raw)), sum(duplicated(raw$OrderID))),
    After = c(nrow(result$clean), sum(is.na(result$clean$Product)), sum(is.na(result$clean$Quantity)),
              sum(is.na(result$clean$Customer)), sum(duplicated(result$clean[-1])), sum(duplicated(result$clean$OrderID))))
  utils::write.csv(metrics, "outputs/before_after.csv", row.names = FALSE)
  cat("\nBEFORE/AFTER COUNTS\n"); print(metrics, row.names = FALSE)
  cat("Reconciliation:", nrow(raw), "=", nrow(result$clean), "+",
      nrow(result$quarantine), "+", nrow(result$duplicates), "\n")
  cat("All row-coverage and clean-data assertions passed.\n")
  cat("dplyr version:", as.character(utils::packageVersion("dplyr")), "\n")
  print(sessionInfo())
}
