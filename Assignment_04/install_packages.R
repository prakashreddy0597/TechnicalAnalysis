# AI-assisted setup for the supplied BDA400 Assignment 4 brief.
# ChatGPT, model/version not exposed; 24 November 2026.
if (file.exists("/usr/bin/curl")) {
  Sys.setenv(PATH = paste("/usr/bin", Sys.getenv("PATH"), sep = .Platform$path.sep))
  options(download.file.method = "curl")
}
if (!requireNamespace("dplyr", quietly = TRUE)) {
  install.packages("dplyr", repos = "https://cloud.r-project.org")
}
cat("dplyr", as.character(packageVersion("dplyr")), "\n")
cat(R.version.string, "\n")
