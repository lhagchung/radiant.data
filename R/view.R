#' Method to create datatables
#'
#' @param object Object of relevant class to render
#' @param ... Additional arguments
#'
#' @seealso See \code{\link{dtab.data.frame}} to create an interactive table from a data.frame
#' @seealso See \code{\link{dtab.explore}} to create an interactive table from an \code{\link{explore}} object
#' @seealso See \code{\link{dtab.pivotr}} to create an interactive table from a \code{\link{pivotr}} object
#'
#' @export
dtab <- function(object, ...) UseMethod("dtab", object)

#' Create a DT table with bootstrap theme
#'
#' @details View, search, sort, etc. your data. For styling options see \url{http://rstudio.github.io/DT/functions.html}
#'
#' @param object Data.frame to display
#' @param vars Variables to show (default is all)
#' @param filt Filter to apply to the specified dataset. For example "price > 10000" if dataset is "diamonds" (default is "")
#' @param rows Select rows in the specified dataset. For example "1:10" for the first 10 rows or "n()-10:n()" for the last 10 rows (default is NULL)
#' @param nr Number of rows of data to include in the table
#' @param na.rm Remove rows with missing values (default is FALSE)
#' @param dec Number of decimal places to show. Default is no rounding (NULL)
#' @param perc Vector of column names to be displayed as a percentage
#' @param filter Show column filters in DT table. Options are "none", "top", "bottom"
#' @param pageLength Number of rows to show in table
#' @param dom Table control elements to show on the page. See \url{https://datatables.net/reference/option/dom}
#' @param style Table formatting style ("bootstrap" or "default")
#' @param rownames Show data.frame rownames. Default is FALSE
#' @param ... Additional arguments
#'
#' @examples
#' \dontrun{
#' dtab(mtcars)
#' }
#'
#' @export
dtab.data.frame <- function(
  object, vars = "", filt = "", rows = NULL,
  nr = NULL, na.rm = FALSE, dec = 3, perc = "",
  filter = "top", pageLength = 10, dom = "", 
  style = "bootstrap", rownames = FALSE, ...
) {

  dat <- get_data(object, vars, filt = filt, rows = rows, na.rm = na.rm)
  if (!is_empty(nr)) {
    dat <- dat[seq_len(nr), , drop = FALSE]
  }

  ## for rounding
  isInt <- sapply(dat, is.integer)
  isDbl <- sapply(dat, is_double)
  dec <- ifelse(is_empty(dec) || dec < 0, 3, round(dec, 0))

  ## don't do normal rounding for perc variables
  isInt[intersect(names(isInt), perc)] <- FALSE
  isDbl[intersect(names(isDbl), perc)] <- FALSE

  ## avoid factor with a huge number of levels
  isBigFct <- function(x) is.factor(x) && length(levels(x)) > 1000
  dat <- mutate_if(dat, isBigFct, as.character)

  ## for display options see https://datatables.net/reference/option/dom
  if (is_empty(dom)) {
    dom <- if (pageLength == -1 || nrow(dat) < pageLength) "t" else "lftip"
  }

  dt_tab <- DT::datatable(
    dat,
    filter = filter,
    selection = "none",
    rownames = rownames,
    ## must use fillContainer = FALSE to address
    ## see https://github.com/rstudio/DT/issues/367
    ## https://github.com/rstudio/DT/issues/379
    fillContainer = FALSE,
    escape = FALSE,
    style = style,
    options = list(
      dom = dom,
      search = list(regex = TRUE),
      columnDefs = list(
        list(orderSequence = c("desc", "asc"), targets = "_all"),
        list(className = "dt-center", targets = "_all")
      ),
      autoWidth = TRUE,
      processing = FALSE,
      pageLength = pageLength,
      lengthMenu = list(c(5, 10, 25, 50, -1), c("5", "10", "25", "50", "All"))
    )
  )

  ## rounding as needed
  if (sum(isDbl) > 0)
    dt_tab <- DT::formatRound(dt_tab, colnames(dat)[isDbl], digits = dec)
  if (sum(isInt) > 0)
    dt_tab <- DT::formatRound(dt_tab, colnames(dat)[isInt], digits = 0)
  if (!is_empty(perc))
    dt_tab <- DT::formatPercentage(dt_tab, perc, digits = dec)

  ## see https://github.com/yihui/knitr/issues/1198
  dt_tab$dependencies <- c(
    list(rmarkdown::html_dependency_bootstrap("bootstrap")),
    dt_tab$dependencies
  )

  dt_tab
}

#' Filter data with user-specified expression
#' @details Filters can be used to view a sample from a selected dataset. For example, runif(nrow(.)) > .9 could be used to sample approximately 10% of the rows in the data and 1:nrow(.) < 101 would select only the first 100 rows in the data. Note: "." references the currently selected dataset.
#' @param dataset Data frame to filter
#' @param filt Filter expression to apply to the specified dataset
#' @param drop Drop unused factor levels after filtering (default is TRUE)
#' @return Filtered data frame
#' @examples
#' select(diamonds, 1:3) %>% filter_data(filt = "price > max(.$price) - 100")
#' select(diamonds, 1:3) %>% filter_data(filt = "runif(nrow(.)) > .995")
#' @export
filter_data <- function(dataset, filt = "", drop = TRUE) {
  if (grepl("([^=!<>])=([^=])", filt)) {
    message("Invalid filter: Never use = in a filter. Use == instead (e.g., year == 2014). Update or remove the expression")
  } else {
    seldat <- try(
      ## use %>% so . will be available to represent the available data in filters
      dataset %>% filter(!! rlang::parse_expr(fix_smart(filt))),
      silent = TRUE
    )
    if (is(seldat, "try-error")) {
      message(paste0("Invalid filter: \"", attr(seldat, "condition")$message, "\". Update or remove the expression"))
    } else {
      if (drop) {
        return(droplevels(seldat))
      } else {
        return(seldat)
      }
    }
  }
  dataset
}

#' Search for a pattern in all columns of a data.frame
#'
#' @param dataset Data.frame to search
#' @param pattern String to match
#' @param ignore.case Should search be case sensitive or not (default is FALSE)
#' @param fixed Allow regular expressions or not (default is FALSE)
#' @seealso See \code{\link{grepl}} for a detailed description of the function arguments
#' @examples
#' publishers %>% filter(search_data(., "^m"))
#' @export
search_data <- function(dataset, pattern, ignore.case = TRUE, fixed = FALSE) {
  mutate_all(
    dataset, 
    funs(grepl(pattern, as.character(.), ignore.case = ignore.case, fixed = fixed))
  ) %>%
    transmute(sel = rowSums(.) > 0) %>%
    pull("sel")
}

#' View data in a shiny-app
#'
#' @details View, search, sort, etc. your data
#'
#' @param dataset Data.frame or name of the dataframe to view
#' @param vars Variables to show (default is all)
#' @param filt Filter to apply to the specified dataset
#' @param rows Select rows in the specified dataset
#' @param na.rm Remove rows with missing values (default is FALSE)
#' @param dec Number of decimals to show
#' @seealso See \code{\link{get_data}} and \code{\link{filter_data}} 
#' @examples
#' \dontrun{
#' view_data(mtcars)
#' }
#'
#' @export
view_data <- function(
  dataset, vars = "", filt = "",
  rows = NULL, na.rm = FALSE, dec = 3
) {

  ## based on http://rstudio.github.io/DT/server.html
  dat <- get_data(dataset, vars, filt = filt, rows = rows, na.rm = na.rm)
  title <- if (is_string(dataset)) paste0("DT:", dataset) else "DT"
  fbox <- if (nrow(dat) > 5e6) "none" else list(position = "top")

  ## avoid factor with a huge number of levels
  isBigFct <- function(x) is.factor(x) && length(levels(x)) > 1000
  dat <- mutate_if(dat, isBigFct, as.character)

  ## for rounding
  isDbl <- sapply(dat, is_double)
  isInt <- sapply(dat, is.integer)
  dec <- ifelse(is_empty(dec) || dec < 0, 3, round(dec, 0))

  shinyApp(
    ui = fluidPage(
      title = title,
      includeCSS(file.path(system.file(package = "radiant.data"), "app/www/style.css")),
      fluidRow(DT::dataTableOutput("tbl")),
      actionButton("stop", "Stop", class = "btn-danger", onclick = "window.close();")
    ),
    server = function(input, output, session) {
      widget <- DT::datatable(
        dat,
        selection = "none",
        rownames = FALSE,
        style = "bootstrap",
        filter = fbox,
        escape = FALSE,
        ## must use fillContainer = FALSE to address
        ## see https://github.com/rstudio/DT/issues/367
        ## https://github.com/rstudio/DT/issues/379
        # fillContainer = FALSE,
        ## works with client-side processing
        extensions = "KeyTable",
        options = list(
          keys = TRUE,
          search = list(regex = TRUE),
          columnDefs = list(
            list(orderSequence = c("desc", "asc"), targets = "_all"),
            list(className = "dt-center", targets = "_all")
          ),
          autoWidth = TRUE,
          processing = FALSE,
          pageLength = 10,
          lengthMenu = list(c(5, 10, 25, 50, -1), c("5", "10", "25", "50", "All"))
        )
      ) %>%
        {if (sum(isDbl) > 0) DT::formatRound(., names(isDbl)[isDbl], dec) else .} %>%
        {if (sum(isInt) > 0) DT::formatRound(., names(isInt)[isInt], 0) else .}
      output$tbl <- DT::renderDataTable(widget)
      observeEvent(input$stop, {
        stopApp(cat("Stopped view_data"))
      })
    }
  )
}
