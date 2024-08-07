leafletProviderDependencies <- function() {
  list(
    get_providers_html_dependency(),
    htmltools::htmlDependency(
      "leaflet-providers-plugin",
      get_package_version("leaflet"),
      "htmlwidgets/plugins/leaflet-providers-plugin",
      package = "leaflet",
      script = "leaflet-providers-plugin.js"
    )
  )
}

#' Add a tile layer from a known map provider
#'
#' @param map the map to add the tile layer to
#' @param provider the name of the provider (see
#'   <https://leaflet-extras.github.io/leaflet-providers/preview/> and
#'   <https://github.com/leaflet-extras/leaflet-providers>)
#' @param layerId the layer id to assign
#' @param group the name of the group the newly created layers should belong to
#'   (for [clearGroup()] and [addLayersControl()] purposes). Human-friendly
#'   group names are permitted--they need not be short, identifier-style names.
#' @param options tile options
#' @param check Check that the specified `provider` matches the available
#'   currently loaded leaflet providers? Defaults to `TRUE`, but can be toggled
#'   to `FALSE` for advanced users.
#' @return modified map object
#'
#' @examples
#' leaflet() %>%
#'   addProviderTiles("Esri.WorldTopoMap") %>%
#'   addProviderTiles("CartoDB.DarkMatter")
#'
#' @export
addProviderTiles <- function(
  map,
  provider,
  layerId = NULL,
  group = NULL,
  options = providerTileOptions(),
  check = TRUE
) {
  if (check) {
    loaded_providers <- leaflet.providers::providers_loaded()
    if (!provider %in% names(loaded_providers$providers)) {
      stop(
        "Unknown tile provider '",
        provider,
        "'; either use a known provider or pass `check = FALSE` to `addProviderTiles()`"
      )
    }
  }
  map$dependencies <- c(map$dependencies, leafletProviderDependencies())
  invokeMethod(map, getMapData(map), "addProviderTiles",
    provider, layerId, group, options)
}

#' @param
#' errorTileUrl,noWrap,opacity,zIndex,updateWhenIdle,detectRetina
#' the tile layer options; see
#' <https://web.archive.org/web/20220702182250/https://leafletjs.com/reference-1.3.4.html#tilelayer>
#' @param ... named parameters to add to the options
#' @rdname addProviderTiles
#' @export
providerTileOptions <- function(errorTileUrl = "", noWrap = FALSE,
  opacity = NULL, zIndex = NULL,
  updateWhenIdle = NULL, detectRetina = FALSE, ...
) {
  opts <- filterNULL(list(
    errorTileUrl = errorTileUrl, noWrap = noWrap,
    opacity = opacity,  zIndex = zIndex,
    updateWhenIdle = updateWhenIdle, detectRetina = detectRetina,
    ...))
  opts
}

#' Providers
#'
#' List of all providers with their variations
#'
#' @format A list of characters
#' @source <https://github.com/leaflet-extras/leaflet-providers/blob/0a9e27f8c6c26956b4e78c26e1945d748e3c2869/leaflet-providers.js>
#'
#' @name providers
#' @export providers
#' @examples
#' providers
NULL
# Active binding added in zzz.R
"providers"

#' @name providers.details
#' @export providers.details
#' @rdname providers
NULL
# Active binding added in zzz.R
"providers.details"

# Active binding added in zzz.R
"providers.version_num"

# Active binding added in zzz.R
"providers.src"

# Active binding added in zzz.R
"providers.dep"

get_providers_html_dependency <- function() {
  if (is.null(providers.dep)) {
    return(create_temp_providers_html_dependency())
  }

  providers.dep
}

create_temp_providers_html_dependency <- function() {
  # for compatibility with older versions of leaflet.providers
  tmpfile <- file.path(tempdir(), paste0("leaflet-providers_", providers.version_num, ".js"))

  if (!file.exists(tmpfile)) {
    src <- providers.src
    writeLines(src, tmpfile)
  }

  htmltools::htmlDependency(
    "leaflet-providers",
    providers.version_num,
    src = dirname(tmpfile),
    script = basename(tmpfile),
    all_files = FALSE
  )
}
