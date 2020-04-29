#!/usr/bin/env Rscript

# Argument Parser ---------------------------------------------------------

suppressMessages(suppressWarnings(library('optparse')))

option_list <- list(
  make_option(c("-t", "--ts"),
    action = "store", default = NA, type = "character",
    help = "Path to the timeseries from which to construct an adjacency matrix."
  ),
  make_option(c("-o", "--out"),
    action = "store", defaul = NA, type = "character",
    help = "Optional name for the matrix. Defualt will be the name of the timeseries."
  )
)

opt <- parse_args(OptionParser(option_list = option_list))

if (is.na(opt$ts)) {
  cat("Input timeseries was unspecified.\n")
  cat("Use ts2adj.R --help for usage.\n")
  quit()
}

ts_path <- opt$ts

if (is.na(opt$out)) {
  output <- paste(sub("\\..*$", "", basename(ts_path)), "tsv", sep = ".")
} else {
  output <- opt$out
}

# Main --------------------------------------------------------------------

timeseries <- as.matrix(unname(read.table(ts_path, header = F)))

#ROIs should be columns, the script I used outputs them as rows.
timeseries <- t(timeseries)

# Create Adjacency matrices.
adjmat <- suppressWarnings(cor(timeseries))
adjmat[is.na(adjmat)] <- NaN

# Write it out.
write.table(
  adjmat,
  file = output,
  sep = "\t",
  row.names = FALSE, col.names = FALSE)
