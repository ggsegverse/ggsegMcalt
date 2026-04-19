#' MCALT Cortical Atlas
#'
#' Cortical parcellation from the Mayo Clinic Adult Lifespan Template (MCALT)
#' ADIR122 atlas.
#'
#' @family ggseg_atlases
#' @family cortical_atlases
#'
#' @references Schwarz CG, et al. (2017). Alzheimer's & Dementia, 13(7):P1071.
#'   \doi{10.1016/j.jalz.2017.06.1071}
#'
#' @return A [ggseg.formats::ggseg_atlas] object (cortical).
#' @import ggseg.formats
#' @export
#' @examples
#' mcalt_cortical()
#' \dontrun{plot(mcalt_cortical())}
mcalt_cortical <- function() .mcalt_cortical

#' MCALT Subcortical Atlas
#'
#' Subcortical parcellation from the Mayo Clinic Adult Lifespan Template (MCALT)
#' ADIR122 atlas.
#'
#' @family ggseg_atlases
#' @family subcortical_atlases
#'
#' @references Schwarz CG, et al. (2017). Alzheimer's & Dementia, 13(7):P1071.
#'   \doi{10.1016/j.jalz.2017.06.1071}
#'
#' @return A [ggseg.formats::ggseg_atlas] object (subcortical).
#' @export
#' @examples
#' mcalt_subcortical()
#' \dontrun{plot(mcalt_subcortical())}
# nolint next: object_usage_linter.
mcalt_subcortical <- function() .mcalt_subcortical
