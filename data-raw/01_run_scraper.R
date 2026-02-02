# data-raw/01_run_scraper.R
# Ejecuta scraping de EspacioCiencia (ANID) para query: "ecosistema de ciencia"
# Exporta CSV final a /data y deja logs en /outputs/logs

suppressWarnings(suppressMessages({
  library(dplyr)
  library(purrr)
  library(cli)
}))

# ---- Config ----
BASE_URL <- "https://espaciociencia.anid.cl"
QUERY <- "ecosistema de ciencia"

MAX_PAGES <- 10      # ajustable
SLEEP_SEC <- 0.8     # rate limit amigable
QUIET <- FALSE

OUT_CSV <- file.path("data", "espaciociencia_ecosistema_ciencia.csv")
LOG_DIR <- file.path("outputs", "logs")
if (!dir.exists(LOG_DIR)) dir.create(LOG_DIR, recursive = TRUE)
LOG_FILE <- file.path(LOG_DIR, paste0("run_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".log"))

# ---- Logger simple ----
log_line <- function(...) {
  msg <- paste0(...)
  cat(msg, "\n", file = LOG_FILE, append = TRUE)
  cli::cli_inform(msg)
}

# ---- Source functions ----
source(file.path("R", "scrape_helpers.R"))
source(file.path("R", "render_helpers.R"))
source(file.path("R", "parse_results.R"))
source(file.path("R", "parse_detail.R"))
source(file.path("R", "build_dataset.R"))

log_line("== espaciociencia-scraper run ==")
log_line("Base URL: ", BASE_URL)
log_line("Query: ", QUERY)
log_line("Max pages: ", MAX_PAGES)
log_line("Sleep sec: ", SLEEP_SEC)

# ---- 1) Collect results ----
log_line("Step 1: collecting result IDs...")
res <- collect_results(
  query = QUERY,
  base_url = BASE_URL,
  max_pages = MAX_PAGES,
  sleep_sec = SLEEP_SEC,
  quiet = QUIET
)

log_line("Found ", nrow(res), " unique result(s).")

if (nrow(res) == 0) {
  log_line("No results found. Stop.")
  stop("No results parsed from results page. Site may be JS-rendered or HTML changed.", call. = FALSE)
}

# ---- 2) Fetch details ----
log_line("Step 2: fetching details...")
details <- purrr::pmap_dfr(
  list(res$id, res$url),
  function(id, url) {
    log_line(" - detail: ", id)
    tryCatch(
      fetch_and_parse_detail(id = id, url = url, sleep_sec = SLEEP_SEC, quiet = QUIET),
      error = function(e) {
        log_line("   ! error on ", id, ": ", e$message)
        tibble::tibble(
          id = id,
          url = url,
          titulo = NA_character_,
          anio = NA_integer_,
          fuente_institucional = guess_fuente_from_id(id)
        )
      }
    )
  }
)

# ---- 3) Merge prelim data (si sirve) ----
log_line("Step 3: merging prelim fields (fallbacks)...")
final <- details |>
  left_join(res |> select(id, titulo_preliminar, anio_preliminar), by = "id") |>
  mutate(
    titulo = ifelse(is.na(titulo) | !nzchar(titulo), titulo_preliminar, titulo),
    anio = ifelse(is.na(anio), anio_preliminar, anio)
  ) |>
  select(fuente_institucional, anio, titulo, id, url)

# ---- 4) Clean + export ----
log_line("Step 4: cleaning and exporting...")
final_clean <- clean_dataset(final)

write_outputs(final_clean, csv_path = OUT_CSV)

log_line("Wrote CSV: ", OUT_CSV)
log_line("Rows: ", nrow(final_clean))
log_line("Done.")

