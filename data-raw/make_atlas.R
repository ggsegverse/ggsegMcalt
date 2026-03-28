# Create MCALT Atlas
#
# Mayo Clinic Adult Lifespan Template ADIR122 parcellation.
#
# Source: https://www.nitrc.org/projects/mcalt/
# Reference: Schwarz CG, et al. (2017). Alzheimer's & Dementia 13(7):P1071.
#
# Date obtained: 2026-03-28
#
# Run with: Rscript data-raw/make_atlas.R

library(ggseg.extra)
library(ggseg.formats)

mcalt <- create_subcortical_from_volume(
  input_volume = here::here("data-raw", "source", "MCALT_ADIR122.nii"),
  atlas_name = "mcalt",
  output_dir = "data-raw",
  skip_existing = TRUE,
  cleanup = FALSE
)

print(mcalt)
plot(mcalt)

.mcalt <- mcalt
usethis::use_data(.mcalt, overwrite = TRUE, compress = "xz", internal = TRUE)
