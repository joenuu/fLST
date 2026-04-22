# This was only used when I had a problem and wanted to move a lot of files.
# It is not relevant in the final project.
# I left it here in case someone encounters a similar problem.

# a function to copy file by pattern

file_copying_by_pattern <- function(path_source, pattern_source, path_target){
  source_files <- list.files(
    path = path_source,
    pattern = pattern_source,
    full.names = TRUE
  )

  file.copy(source_files, path_target)
}


