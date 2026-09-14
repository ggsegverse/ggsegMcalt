# Create MCALT Atlas
#
# Source: https://www.nitrc.org/projects/mcalt/
# Reference: Schwarz CG, et al. (2017). Alzheimer's & Dementia 13(7):P1071.
# Date obtained: 2026-03-28
#
# The volume is a 1.5 mm RAS grid, so registration stays "header";
# average/mni152.register.dat is only exact on the 1 mm LAS MNI152 grid.
#
# MCALT publishes no lookup table, so one is built here. The names stay the
# generic region_NNNN the pipeline would have generated, because upstream
# publishes no label names; what the table adds is a distinct colour per
# index and a type column. The type column is what keeps the deep grey,
# brainstem and cerebellar indices off the surface: without it the
# vertex-count fallback both handed index 42 a whole hemisphere and dropped
# 23 of the 122 labels from the atlas entirely. Each index below was placed
# by its centroid in the volume's own world coordinates.
#
# Run with: Rscript data-raw/make_atlas.R

library(ggseg.extra)
library(ggseg.formats)

Sys.setenv(FREESURFER_HOME = "/Applications/freesurfer/7.4.1")

input_volume <- here::here("data-raw", "source", "MCALT_ADIR122.nii")

volume_idx <- sort(unique(as.vector(RNifti::readNifti(input_volume))))
volume_idx <- as.integer(volume_idx[volume_idx > 0])

accumbens <- c(21, 22)
hippocampus <- c(37, 38)
amygdala <- c(41, 42)
basal_ganglia <- 71:76
thalamus <- c(77, 78)
cerebellum <- 91:116
brainstem <- c(117, 118)

non_cortical <- c(
  accumbens, hippocampus, amygdala, basal_ganglia,
  thalamus, cerebellum, brainstem
)

colours <- grDevices::col2rgb(grDevices::hcl(
  h = seq(15, 375, length.out = length(volume_idx) + 1)[
    seq_along(volume_idx)
  ],
  l = 65,
  c = 100
))

lut <- data.frame(
  idx = volume_idx,
  label = sprintf("region_%04d", volume_idx),
  R = as.integer(colours["red", ]),
  G = as.integer(colours["green", ]),
  B = as.integer(colours["blue", ]),
  A = 0L,
  type = ifelse(volume_idx %in% non_cortical, "subcortical", "cortical")
)

atlases <- create_wholebrain_from_volume(
  input_volume = input_volume,
  input_lut = lut,
  atlas_name = "mcalt",
  output_dir = "data-raw",
  registration = "header",
  skip_existing = TRUE,
  cleanup = FALSE
)

.mcalt_cortical <- atlas_smooth(
  atlas_simplify(atlases$cortical, keep = 0.2),
  smoothness = 0.4,
  method = "chaikin"
)

.mcalt_subcortical <- atlas_smooth(
  atlas_simplify(atlases$subcortical, keep = 0.5),
  smoothness = 0.4,
  method = "chaikin"
)

usethis::use_data(
  .mcalt_cortical, .mcalt_subcortical,
  overwrite = TRUE, compress = "xz", internal = TRUE
)
