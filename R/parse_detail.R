# R/parse_detail.R

suppressWarnings(suppressMessages({
  library(rvest)
  library(dplyr)
  library(stringr)
}))

# Extraer título/año desde una página de detalles.
# Como el HTML puede variar, lo hacemos por heurísticas:
# - Título: h1, h2 prominente o <title> del documento.
# - Año: buscar primer año 4 dígitos en bloques de metadatos / texto.
# - Fuente institucional: preferimos inferir por ID, pero si hay un label visible, lo usamos.
parse_detail_page <- function(html, id = NA_character_, url = NA_character_) {
  page <- read_html(html)
  
  # 1) Título
  h1 <- page |> html_elements("h1") |> html_text2()
  h2 <- page |> html_elements("h2") |> html_text2()
  ttl <- page |> html_element("title") |> html_text2()
  
  cand <- c(h1, h2)
  cand <- cand[!is.na(cand)]
  cand <- normalize_whitespace(cand)
  cand <- cand[nzchar(cand)]
  
  # fallback SOLO si h1/h2 no trae nada
  if (length(cand) == 0 && !is.na(ttl) && nzchar(ttl)) {
    cand <- normalize_whitespace(ttl)
  }
  
  titulo <- if (length(cand) > 0) cand[[1]] else NA_character_
  
  # 2) Texto total "metadatos" (para año)
  body_text <- page |> html_text2()
  body_text <- normalize_whitespace(body_text)
  anio <- safe_int_year(body_text)
  
  # 3) Fuente institucional (heurística simple)
  fuente <- guess_fuente_from_id(id)
  
  tibble(
    id = id,
    url = url,
    titulo = titulo,
    anio = anio,
    fuente_institucional = fuente
  )
}

fetch_and_parse_detail <- function(id, url, sleep_sec = 0.7, quiet = FALSE) {
  # Renderiza con JS (igual que resultados), porque /detalles carga contenido dinámico
  html <- render_html_chromote(url, wait = 2, quiet = quiet)
  rate_limit_sleep(sleep_sec)
  parse_detail_page(html, id = id, url = url)
}
