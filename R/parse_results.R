# R/parse_results.R

suppressWarnings(suppressMessages({
  library(rvest)
  library(stringr)
  library(dplyr)
}))

# Parsear página de resultados para obtener IDs + URL detalle + título preliminar + año preliminar (si aparece).
parse_results_page <- function(html, base_url = "https://espaciociencia.anid.cl") {
  page <- read_html(html)
  
  # Estrategia robusta: buscar enlaces que contengan "/detalles?id="
  links <- page |>
    html_elements("a") |>
    html_attr("href")
  
  links <- links[!is.na(links)]
  links <- unique(links)
  
  det <- links[str_detect(links, "/detalles\\?id=")]
  if (length(det) == 0) {
    return(dplyr::tibble(
      id = character(),
      url = character(),
      titulo_preliminar = character(),
      anio_preliminar = integer()
    ))
  }
  
  # Convertir a URL absoluta
  det_url <- ifelse(str_detect(det, "^https?://"),
                    det,
                    paste0(base_url, det))
  
  ids <- str_match(det, "id=([^&]+)")[, 2]
  
  # Intentar capturar el texto visible del enlace como título preliminar
  # (No siempre es el título real, pero puede ayudar)
  # Para mapear texto de enlace: buscamos todos los <a> con esos href.
  nodes <- page |>
    html_elements("a")
  
  hrefs <- nodes |> html_attr("href")
  texts <- nodes |> html_text2()
  
  # map href->texto
  idx <- match(det, hrefs)
  titulo_pre <- texts[idx]
  titulo_pre <- ifelse(is.na(titulo_pre), "", titulo_pre)
  
  # Año preliminar: intentar extraer desde texto cercano (fallback: desde título preliminar)
  anio_pre <- vapply(titulo_pre, function(tt) {
    y <- safe_int_year(tt)
    y
  }, integer(1))
  
  tibble(
    id = ids,
    url = det_url,
    titulo_preliminar = normalize_whitespace(titulo_pre),
    anio_preliminar = anio_pre
  ) |>
    distinct(id, .keep_all = TRUE) |>
    filter(!is.na(id), nzchar(id))
}

# Parsear múltiples páginas (paginación por "page=" si existe)
# Si el sitio no usa page=, igual funciona con max_pages=1.
collect_results <- function(query,
                            base_url = "https://espaciociencia.anid.cl",
                            max_pages = 10,
                            sleep_sec = 0.7,
                            quiet = FALSE) {
  # URL de resultados observado: /resultados?lookFor=...
  # Codificación segura:
  q_enc <- URLencode(query, reserved = TRUE)
  
  all <- list()
  
  for (p in seq_len(max_pages)) {
    # Probar con parámetro page=
    url <- paste0(base_url, "/resultados?lookFor=", q_enc, "&page=", p)
    
    html <- render_html_chromote(url, wait = 2, quiet = quiet)
    df <- parse_results_page(html, base_url = base_url)
    
    if (nrow(df) == 0) {
      # Si en page=1 no aparece nada, probamos sin page=
      if (p == 1) {
        url2 <- paste0(base_url, "/resultados?lookFor=", q_enc)
        html2 <- render_html_chromote(url2, wait = 2, quiet = quiet)
        df2 <- parse_results_page(html2, base_url = base_url)
        if (nrow(df2) == 0) return(df2)
        all[[length(all) + 1]] <- df2
      }
      break
    }
    
    all[[length(all) + 1]] <- df
    
    # Si viene menos de ~5 resultados, muchas veces es última página
    if (nrow(df) < 5) break
    
    rate_limit_sleep(sleep_sec)
  }
  
  bind_rows(all) |>
    distinct(id, .keep_all = TRUE)
}
