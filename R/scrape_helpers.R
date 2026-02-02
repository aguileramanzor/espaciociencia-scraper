# R/scrape_helpers.R

# Helpers para descargar HTML con reintentos, pausas y user-agent.
# Usamos httr2 porque es más robusto que httr para reintentos.

suppressWarnings(suppressMessages({
  library(httr2)
  library(cli)
}))

ua_default <- function() {
  # User-Agent honesto y estable; evita parecer "bot genérico"
  "espaciociencia-scraper (R; httr2; contact: your-email-or-gh-handle)"
}

rate_limit_sleep <- function(seconds = 0.7) {
  Sys.sleep(seconds)
}

http_get_html <- function(url,
                          user_agent = ua_default(),
                          retries = 4,
                          backoff_base = 1,
                          timeout_sec = 30,
                          quiet = FALSE) {
  last_err <- NULL
  
  for (i in seq_len(retries)) {
    if (!quiet) cli::cli_inform(c("i" = "GET {url} (try {i}/{retries})"))
    
    req <- httr2::request(url) |>
      httr2::req_user_agent(user_agent) |>
      httr2::req_timeout(timeout_sec)
    
    resp <- tryCatch(
      httr2::req_perform(req),
      error = function(e) e
    )
    
    if (inherits(resp, "error")) {
      last_err <- resp
      wait <- backoff_base * i
      if (!quiet) cli::cli_warn("Request failed: {resp$message}. Retrying in {wait}s...")
      Sys.sleep(wait)
      next
    }
    
    status <- httr2::resp_status(resp)
    
    # 200 OK
    if (status >= 200 && status < 300) {
      txt <- httr2::resp_body_string(resp, encoding = "UTF-8")
      return(txt)
    }
    
    # 429 Too Many Requests / 5xx server errors: reintentar
    if (status == 429 || (status >= 500 && status <= 599)) {
      wait <- backoff_base * i
      if (!quiet) cli::cli_warn("HTTP {status}. Retrying in {wait}s...")
      Sys.sleep(wait)
      next
    }
    
    # 4xx (except 429): suele ser definitivo
    msg <- paste0("HTTP ", status, " for URL: ", url)
    stop(msg, call. = FALSE)
  }
  
  # Si agotamos reintentos
  if (!is.null(last_err)) stop(last_err$message, call. = FALSE)
  stop("Failed to GET after retries: ", url, call. = FALSE)
}

normalize_whitespace <- function(x) {
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("\\s{2,}", " ", x)
  trimws(x)
}

safe_int_year <- function(x) {
  # Extrae primer año de 4 dígitos entre 1900-2099 si existe
  m <- regmatches(x, regexpr("(19|20)\\d{2}", x))
  if (length(m) == 0 || is.na(m) || m == "") return(NA_integer_)
  as.integer(m)
}

guess_fuente_from_id <- function(id) {
  # Regla simple: prefijo antes del primer "_"
  if (is.na(id) || !nzchar(id)) return(NA_character_)
  pref <- sub("_.*$", "", id)
  pref <- toupper(pref)
  pref
}
