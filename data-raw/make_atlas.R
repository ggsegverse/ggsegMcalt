# Create MCALT Atlas
#
# Source: https://www.nitrc.org/projects/mcalt/
# Reference: Schwarz CG, et al. (2017). Alzheimer's & Dementia 13(7):P1071.
# Date obtained: 2026-03-28
#
# Run with: Rscript data-raw/make_atlas.R

library(ggseg.extra)
library(ggseg.formats)

Sys.setenv(FREESURFER_HOME = "/Applications/freesurfer/7.4.1")

atlases <- create_wholebrain_from_volume(
  input_volume = here::here("data-raw", "source", "MCALT_ADIR122.nii"),
  atlas_name = "mcalt",
  output_dir = "data-raw",
  skip_existing = TRUE,
  cleanup = FALSE
)

objs <- list()
if (!is.null(atlases$cortical)) {
  objs$.mcalt_cortical <- atlases$cortical
  print(atlases$cortical)
  plot(atlases$cortical)
}
if (!is.null(atlases$subcortical)) {
  objs$.mcalt_subcortical <- atlases$subcortical
  print(atlases$subcortical)
  plot(atlases$subcortical)
}

do.call(usethis::use_data, c(objs, list(overwrite = TRUE, compress = "xz", internal = TRUE)))
