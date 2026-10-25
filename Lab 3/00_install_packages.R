# 只需运行一次：安装本文使用的两个 R 扩展包及依赖。
# 安装到项目目录，不修改系统 R 库。
dir.create('.r_library', showWarnings = FALSE)
.libPaths(c(normalizePath('.r_library'), .Library))
required <- c('vars', 'openxlsx')
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  options(timeout = max(300, getOption('timeout')))
  install.packages(missing, repos = 'https://cloud.r-project.org',
                   lib = '.r_library', type = if (.Platform$OS.type == 'windows') 'binary' else 'source')
}
stopifnot(all(vapply(required, requireNamespace, logical(1), quietly = TRUE)))
print(vapply(required, function(p) as.character(packageVersion(p)), character(1)))
