#' MCALT Brain Atlas
#'
#' Brain atlas for the Mayo Clinic Adult Lifespan Template (MCALT)
#' cortical parcellation, optimized for aging and Alzheimer's Disease research.
#'
#' @family ggseg_atlases
#'
#' @references Schwarz CG, et al. (2017). "A large-scale comparison of cortical
#'   thickness and volume methods for measuring Alzheimer's disease severity."
#'   *NeuroImage: Clinical*, 11:802-812.
#'   \doi{10.1016/j.nicl.2016.01.019}
#'
#' @return A [ggseg.formats::ggseg_atlas] object.
#' @import ggseg.formats
#' @export
#' @examples
#' mcalt()
# fmt: skip
#' plot(mcalt())
mcalt <- function() .mcalt
