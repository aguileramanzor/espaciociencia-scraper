# R/render_helpers.R
# Renderizado headless (JS) para páginas que no traen resultados en HTML inicial.

suppressWarnings(suppressMessages({
  library(chromote)
  library(cli)
}))

render_html_chromote <- function(url, wait = 2, quiet = FALSE) {
  if (!quiet) cli::cli_inform(c("i" = "Chromote render: {url}"))
  
  b <- chromote::ChromoteSession$new()
  
  # Ir a la página
  b$Page$navigate(url = url)
  b$Page$loadEventFired()
  
  # Espera extra para que cargue contenido JS (cards de resultados)
  Sys.sleep(wait)
  
  # Obtener HTML ya renderizado
  html <- b$Runtime$evaluate("document.documentElement.outerHTML")$result$value
  
  # Cerrar sesión
  b$close()
  
  html
}
