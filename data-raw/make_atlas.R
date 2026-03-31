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

.mcalt_cortical <- atlases$cortical
.mcalt_subcortical <- atlases$subcortical
.mcalt_cerebellar <- atlases$cerebellar

print(.mcalt_cortical)
plot(.mcalt_cortical)
print(.mcalt_subcortical)
plot(.mcalt_subcortical)

if (!is.null(.mcalt_cerebellar)) {
  print(.mcalt_cerebellar)
  plot(.mcalt_cerebellar)
  usethis::use_data(.mcalt_cortical, .mcalt_subcortical,
    .mcalt_cerebellar, overwrite = TRUE, compress = "xz", internal = TRUE)
} else {
  usethis::use_data(.mcalt_cortical, .mcalt_subcortical,
    overwrite = TRUE, compress = "xz", internal = TRUE)
}
