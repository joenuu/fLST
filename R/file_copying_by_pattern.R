file_copying_by_pattern <- function(path_source, pattern_source, path_target){
  source_files <- list.files(
    path = path_source,
    pattern = pattern_source,
    full.names = TRUE
  )

  file.copy(source_files, path_target)
}


