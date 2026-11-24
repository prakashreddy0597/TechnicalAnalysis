# AI-assisted technical setup, 24 November 2026. Tool: ChatGPT; model/version not
# exposed. The attached BDA400 Assignment 2 brief specifies quantmod and TTR.
# Installation is verified from actual package-version output, not assumed.
required <- c("quantmod", "TTR")
# In this managed workspace the system curl uses the configured proxy CA trust.
# Keep TLS verification enabled; change only the downloader, not the data source.
if (file.exists("/usr/bin/curl")) {
  Sys.setenv(PATH = paste("/usr/bin", Sys.getenv("PATH"), sep = .Platform$path.sep))
  options(download.file.method = "curl")
}
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}
for (package in required) {
  stopifnot(requireNamespace(package, quietly = TRUE))
  cat(package, as.character(utils::packageVersion(package)), "\n")
}
cat(R.version.string, "\n")
