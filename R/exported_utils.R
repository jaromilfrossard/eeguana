#' Pipe operator
#'
#' See \code{magrittr::\link[magrittr]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom magrittr %>%
#' @usage lhs \%>\% rhs
NULL


#' Convenience function for range subsets
#'
#' `between` is a thin wrapper for the between function of [data.table::between]. 
#' It is equivalent to x >= lower & x <= upper when incbounds=TRUE, or x > lower & y < upper when FALSE. In comparison
#' with [dplyr::between], it doesn't loose the class of its argument, and it's more appropiate for manipulating 
#' the column `.sample`. For more information and the description of the arguments, see [data.table::between].
#' @name between
#' @importFrom data.table between
#' 
#' @examples 
#' 
#' library(dplyr)
#' data_faces_ERPs %>% 
#'      filter(.sample %>% between(10,100))
#' 
#' # Compare with:
#' \dontrun{
#' data_faces_ERPs %>% 
#'      filter(.sample %>% dplyr::between(10,100))
#' }
#' @export
NULL