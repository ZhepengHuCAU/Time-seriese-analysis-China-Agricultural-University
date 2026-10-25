# Optional, NOT part of the strict replication.
# Run from the RStudio project root AFTER the baseline replication.
# Requires internet only if data/raw/IGREA_snapshot.csv is absent.
# Does not overwrite baseline estimates. No bootstrap uncertainty is estimated here.

if (dir.exists('.r_library')) .libPaths(c(normalizePath('.r_library'), .libPaths()))
suppressPackageStartupMessages(library(vars))
suppressPackageStartupMessages(library(openxlsx))
stopifnot(file.exists('data/kilian_analysis_data.xlsx'))
source('R/functions_svar.R', encoding = 'UTF-8')
snapshot <- 'data/raw/IGREA_snapshot.csv'
if (!file.exists(snapshot)) {
  url <- 'https://fred.stlouisfed.org/graph/fredgraph.csv?id=IGREA'
  download.file(url, snapshot, mode = 'wb', method = 'libcurl')
  writeLines(c(paste('URL:', url), paste('Retrieved:', Sys.time()),
               'Revised index snapshot; original oil production/price are retained.'),
             'data/raw/IGREA_snapshot_provenance.txt')
}
new <- read.csv(snapshot, na.strings = c('.', 'NA', ''))
stopifnot(ncol(new) == 2L, 'IGREA' %in% names(new))
new_dates <- as.Date(new[[1]])
stopifnot(!anyDuplicated(new_dates), !anyNA(new_dates))
original <- read.xlsx('data/kilian_analysis_data.xlsx', sheet = 'monthly_svar', detectDates = TRUE)
ix <- match(as.Date(original$date), new_dates)
stopifnot(!anyNA(ix), all(is.finite(new$IGREA[ix])))
y0 <- as.matrix(original[, -1]); y1 <- y0
y1[, 2] <- new$IGREA[ix]
B_restrictions <- matrix(c(NA, 0, 0, NA, NA, 0, NA, NA, NA), 3, byrow = TRUE)
fit_svar <- function(y) SVAR(VAR(y, p = 24, type = 'const'),
  estmethod = 'scoring', Bmat = B_restrictions, max.iter = 1000,
  conv.crit = 1e-10, lrtest = FALSE)
m0 <- fit_svar(y0); m1 <- fit_svar(y1)
r0 <- paper_irf(irf(m0, n.ahead = 15, boot = FALSE))
r1 <- paper_irf(irf(m1, n.ahead = 15, boot = FALSE))
dir.create('output/revised_index_sensitivity', showWarnings = FALSE)
write.csv(data.frame(date = original$date, original_index = y0[, 2], revised_index = y1[, 2]),
          'output/revised_index_sensitivity/index_comparison.csv', row.names = FALSE)
out <- list()
for (j in 1:3) for (i in 1:3) out[[length(out) + 1L]] <- data.frame(month = 0:15, response = i, shock = j,
  original = r0[i, j, ], revised_index_only = r1[i, j, ], difference = r1[i, j, ] - r0[i, j, ])
write.csv(do.call(rbind, out), 'output/revised_index_sensitivity/irf_comparison.csv', row.names = FALSE)
saveRDS(list(original = m0, revised_index_only = m1, snapshot_md5 = tools::md5sum(snapshot)),
        'output/revised_index_sensitivity/models.rds')
cat('Revised-index-only sensitivity complete. Sample remains 1973-02 to 2007-12.\n')
