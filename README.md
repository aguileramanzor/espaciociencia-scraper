# espaciociencia-scraper
Este repositorio contiene un scraper desarrollado en R para construir un dataset a partir del buscador del sitio Espacio Ciencia (https://espaciociencia.anid.cl/), para identificar publicaciones según el término “ecosistema de ciencia”.

El proyecto está diseñado bajo criterios de reproducibilidad, utilizando renv para el control del entorno y una estructura estándar compatible con GitHub.

El objetivo es construir un dataset estructurado que recopile publicaciones indexadas en Espacio Ciencia que contienen el término “ecosistema de ciencia”, con el fin de servir como insumo para análisis exploratorios.

La extracción de información se realiza a partir del buscador interno del sitio Espacio Ciencia, utilizando como término de búsqueda exacto:

"ecosistema de ciencia"

El scraper recorre las páginas de resultados asociadas a esta búsqueda y, para cada registro identificado, extrae información desde la página de detalle correspondiente.

El dataset corresponde a las primeras 10 páginas de resultados del buscador para el término indicado e incluye 200 publicaciones.

El alcance está definido explícitamente mediante el parámetro MAX_PAGES = 10 en el script principal.

Este recorte se utiliza como muestra controlada, priorizando la validación del proceso de scraping y la calidad de los metadatos extraídos.

El dataset final (data/espaciociencia_ecosistema_ciencia.csv) incluye las siguientes variables:

fuente_institucional: institución asociada a la publicación (inferida principalmente desde el identificador del registro).

anio: año de publicación.

titulo: título de la publicación.

id: identificador interno del registro en Espacio Ciencia.

url: enlace a la página de detalle de la publicación.

El sitio Espacio Ciencia utiliza renderizado dinámico (JavaScript) tanto en el listado de resultados como en las páginas de detalle.

Por esta razón, el scraper utiliza Chromote (Chrome en modo headless) para renderizar las páginas antes de extraer el HTML.

El entorno de ejecución está controlado mediante renv, lo que permite reproducir el scraper en otros equipos.

El buscador de Espacio Ciencia no expone un API pública documentada, por lo que la extracción depende de la estructura actual del sitio web.

Cambios futuros en el diseño o en el comportamiento del sitio pueden requerir ajustes en los selectores y funciones de scraping.

Para ejecutar el scraper desde cero:

renv::restore()
source("data-raw/01_run_scraper.R")