# R/build_dataset.R

suppressWarnings(suppressMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(janitor)
}))

clean_dataset <- function(df) {
  df |>
    mutate(
      titulo = normalize_whitespace(titulo),
      fuente_institucional = normalize_whitespace(toupper(fuente_institucional)),
      # Año: asegurar entero o NA
      anio = suppressWarnings(as.integer(anio))
    ) |>
    distinct(id, .keep_all = TRUE) |>
    filter(!is.na(titulo), nzchar(titulo)) |>
    arrange(desc(anio), titulo) |>
    janitor::clean_names()
}

write_outputs <- function(df,
                          csv_path = file.path("data", "espaciociencia_ecosistema_ciencia.csv")) {
  if (!dir.exists(dirname(csv_path))) dir.create(dirname(csv_path), recursive = TRUE)
  readr::write_csv(df, csv_path)
  invisible(csv_path)
}
