#' Add a color legend to a map
#'
#' When a color palette function is used in a map (e.g.,
#' [colorNumeric()]), a color legend can be automatically derived from
#' the palette function. You can also manually specify the colors and labels for
#' the legend.
#'
#' The `labFormat` argument is a function that takes the argument
#' `type = c("numeric", "bin", "quantile", "factor")`, plus, arguments for
#' different types of color palettes. For the `colorNumeric()` palette,
#' `labFormat` takes a single argument, which is the breaks of the numeric
#' vector, and returns a character vector of the same length. For
#' `colorBin()`, `labFormat` also takes a vector of breaks of length
#' `n` but should return a character vector of length `n - 1`, with
#' the `i`-th element representing the interval `c(x[i], x[i + 1])`.
#' For `colorQuantile()`, `labFormat` takes two arguments, the quantiles
#' and the associated probabilities (each of length `n`), and should return
#' a character vector of length `n - 1` (similar to the `colorBin()`
#' palette). For `colorFactor()`, `labFormat` takes one argument, the
#' unique values of the factor, and should return a character vector of the same
#' length.
#'
#' By default, `labFormat` is basically `format(scientific = FALSE,
#' big.mark = ",")` for the numeric palette, `as.character()` for the
#' factor palette, and a function to return labels of the form \samp{x[i] - x[i
#' + 1]} for bin and quantile palettes (in the case of quantile palettes,
#' `x` is the probabilities instead of the values of breaks).
#' @inheritParams setView
#' @param position the position of the legend
#' @param pal the color palette function, generated from
#'   [colorNumeric()], `colorBin()`, `colorQuantile()`, or
#'   `colorFactor()`
#' @param values the values used to generate colors from the palette function
#' @param na.label the legend label for `NA`s in `values`
#' @param bins an approximate number of tick-marks on the color gradient for the
#'   `colorNumeric` palette if it is of length one; you can also provide a
#'   numeric vector as the pre-defined breaks (equally spaced)
#' @param colors a vector of (HTML) colors to be used in the legend if
#'   `pal` is not provided
#' @param opacity the opacity of colors
#' @param labels a vector of text labels in the legend corresponding to
#'   `colors`
#' @param labFormat a function to format the labels derived from `pal` and
#'   `values` (see Details below to know what `labelFormat()` returns
#'   by default; you can either use the helper function `labelFormat()`, or
#'   write your own function)
#' @param title the legend title
#' @param className extra CSS classes to append to the control, space separated
#' @param layerId the ID of the legend; subsequent calls to `addLegend()`
#'   or `addControl()` with the same `layerId` will replace this
#'   legend. The ID can also be used with `removeControl()`.
#' @param group `group` name of a leaflet layer group.
#'   Supplying this value will tie the legend to the leaflet layer group
#'   with this name and will auto add/remove the legend as the
#'   group is added/removed, for example via `layerControl()`.
#'   You will need to set the `group` when you add a layer
#'   (e.g., [addPolygons()]) and supply the same name here.
#' @template data-getMapData
#' @example inst/examples/legend.R
#' @export
addLegend <- function(
  map, position = c("topright", "bottomright", "bottomleft", "topleft"),
  pal, values, na.label = "NA", bins = 7, colors, opacity = 0.5, labels = NULL,
  labFormat = labelFormat(), title = NULL, className = "info legend",
  layerId = NULL, group = NULL, data = getMapData(map)
) {
  position <- match.arg(position)
  type <- "unknown"; na.color <- NULL
  extra <- NULL  # only used for numeric palettes to store extra info

  if (!missing(pal)) {
    if (!missing(colors))
      stop("You must provide either 'pal' or 'colors' (not both)")

    # a better default title when values is formula
    if (missing(title) && inherits(values, "formula")) title <- deparse(values[[2]])
    values <- evalFormula(values, data)

    type <- attr(pal, "colorType", exact = TRUE)
    args <- attr(pal, "colorArgs", exact = TRUE)
    na.color <- args$na.color
    # If na.color is transparent, don't show it on the legend
    if (!is.null(na.color) && col2rgb(na.color, alpha = TRUE)[[4]] == 0) {
      na.color <- NULL
    }
    if (type != "numeric" && !missing(bins))
      warning("'bins' is ignored because the palette type is not numeric")

    if (type == "numeric") {

      # choose pretty cut points to draw tick-marks on the color gradient if
      # 'bins' is the number of bins, otherwise 'bins' is just the breaks
      cuts <- if (length(bins) == 1) pretty(values, n = bins) else bins
      if (length(bins) > 2)
        if (!all(abs(diff(bins, differences = 2)) <= sqrt(.Machine$double.eps)))
          stop("The vector of breaks 'bins' must be equally spaced")
      n <- length(cuts)
      r <- range(values, na.rm = TRUE)
      # pretty cut points may be out of the range of `values`
      cuts <- cuts[cuts >= r[1] & cuts <= r[2]]
      n <- length(cuts)
      p <- (cuts - r[1]) / (r[2] - r[1])  # percents relative to min(values)

      # [    |       |       |  ...  |    ]
      # min  p1      p2      p3 ...  pn   max
      #  |   +   |   +   |   +  ...  +   |
      # here |+| denotes a table row, and there are n rows

      # Since min and max may exceed the limits of the cut points, the client
      # needs to know the first and last cut points in order to place the tick
      # marks properly relative to the gradient.
      extra <- list(p_1 = p[1], p_n = p[n])
      # syntax for the color gradient: linear-gradient(start-color, color1 p1%,
      # color2 p2%, ..., colorn pn%, end-color])
      p <- c("", paste0(100 * p, "%"), "")
      colors <- pal(c(r[1], cuts, r[2]))
      colors <- paste(colors, p, sep = " ", collapse = ", ")
      labels <- labFormat(type = "numeric", cuts)

    } else if (type == "bin") {

      cuts <- args$bins
      n <- length(cuts)
      # use middle points to represent intervals
      mids <- (cuts[-1] + cuts[-n]) / 2
      colors <- pal(mids)
      labels <- labFormat(type = "bin", cuts)

    } else if (type == "quantile") {

      p <- args$probs
      n <- length(p)
      # the "middle points" in this case are the middle probabilities
      cuts <- quantile(values, probs = p, na.rm = TRUE)
      mids <- quantile(values, probs = (p[-1] + p[-n]) / 2, na.rm = TRUE)
      colors <- pal(mids)
      labels <- labFormat(type = "quantile", cuts, p)

    } else if (type == "factor") {

      v <- sort(unique(na.omit(values)))
      colors <- pal(v)
      labels <- labFormat(type = "factor", v)

    } else stop("Palette function not supported")

    if (!any(is.na(values))) na.color <- NULL
  } else {
    if (length(colors) != length(labels))
      stop("'colors' and 'labels' must be of the same length")
  }

  legend <- list(
    colors = I(unname(colors)), labels = I(unname(labels)),
    na_color = na.color, na_label = na.label, opacity = opacity,
    position = position, type = type, title = title, extra = extra,
    layerId = layerId, className = className, group = group
  )
  invokeMethod(map, data, "addLegend", legend)
}

#' @param prefix a prefix of legend labels
#' @param suffix a suffix of legend labels
#' @param between a separator between `x[i]` and `x[i + 1]` in legend
#'   labels (by default, it is a dash)
#' @param digits the number of digits of numeric values in labels
#' @param big.mark the thousand separator
#' @param transform a function to transform the label value
#' @rdname addLegend
#' @export
labelFormat <- function(
  prefix = "", suffix = "", between = " &ndash; ", digits = 3, big.mark = ",",
  transform = identity
) {

  formatNum <- function(x) {
    format(
      round(transform(x), digits), trim = TRUE, scientific = FALSE,
      big.mark = big.mark
    )
  }

  function(type, ...) {
    switch(
      type,
      numeric = (function(cuts) {
        paste0(prefix, formatNum(cuts), suffix)
      })(...), # nolint
      bin = (function(cuts) {
        n <- length(cuts)
        paste0(prefix, formatNum(cuts[-n]), between, formatNum(cuts[-1]), suffix)
      })(...), # nolint
      quantile = (function(cuts, p) {
        n <- length(cuts)
        p <- paste0(round(p * 100), "%")
        cuts <- paste0(formatNum(cuts[-n]), between, formatNum(cuts[-1]))
        # mouse over the legend labels to see the values (quantiles)
        paste0(
          "<span title=\"", cuts, "\">", prefix, p[-n], between, p[-1], suffix,
          "</span>"
        )
      })(...), # nolint
      factor = (function(cuts) {
        paste0(prefix, as.character(transform(cuts)), suffix)
      })(...) # nolint
    )
  }

}
