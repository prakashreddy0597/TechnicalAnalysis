# AI-generated synthetic checks, ChatGPT, 24 November 2026.
# This file supports verification; it is not a claim of student manual testing.
source("rachamalla_bhanu_clean_sales_data.R")
raw <- read.csv("data/sales_data_dirty.csv", na.strings = c("", "NA"), stringsAsFactors = FALSE)
result <- clean_sales_data(raw)
stopifnot(nrow(result$clean) == 378L, nrow(result$duplicates) == 9L,
          nrow(result$quarantine) == 223L,
          identical(result$conflict_ids, 265L),
          setequal(result$quarantine$SourceRow[result$quarantine$OrderID == 265], c(265L,608L)))
# Repeated customer names are normal repeated business entities, not duplicate rows.
stopifnot(length(unique(result$clean$Customer)) == 8L,
          anyDuplicated(result$clean$Customer) > 0L,
          !anyDuplicated(result$clean$OrderID))
# Retaining 300 is deliberate: it is below the chosen fitted upper price fence.
stopifnot(result$thresholds$Upper[result$thresholds$Field == "Price"] > 300,
          sum(result$clean$Price == 300) == 3L,
          all(result$clean$Quantity <= 100))
# A second pass must not change any business values or exclude more records.
fields <- c("OrderID", "Product", "Quantity", "Price", "Customer")
again <- clean_sales_data(result$clean[fields])
stopifnot(identical(result$clean[fields], again$clean[fields]))
fixture <- data.frame(OrderID=1:4, Product=c(" widget ","WIDGET","GADGET","thingamajig"),
                      Quantity=c(2,5,10,20),Price=c(10,20,30,40),
                      Customer=c(" ALICE ","alice","BOB","Eve"))
normalized <- clean_sales_data(fixture)
stopifnot(identical(normalized$clean$Product,c("Widget","Widget","Gadget","Thingamajig")),
          identical(normalized$clean$Customer,c("alice","alice","bob","eve")))
duplicate_fixture <- rbind(fixture,fixture[1,])
stopifnot(nrow(clean_sales_data(duplicate_fixture)$duplicates)==1L)
missing_customer <- rbind(fixture,transform(fixture[1,],OrderID=5L,Customer=NA_character_))
stopifnot(clean_sales_data(missing_customer)$quarantine$Disposition=="missing_customer")
bad <- tryCatch(clean_sales_data(raw,quantity_multiplier=numeric(0)),error=conditionMessage)
stopifnot(is.character(bad),grepl("positive scalars",bad))
cat("PASS: real-input reconciliation, duplicate/conflict separation, all eight customers retained,\n")
cat("price-screen interpretation, idempotent business values, synthetic label normalization,\n")
cat("normalized duplicate handling, missing-customer quarantine and multiplier validation.\n")
