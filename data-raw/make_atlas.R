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
# 23 of the 122 labels from the atlas entirely.
#
# Each index group below was read off the centroids of the volume's own world
# coordinates, and check_group_geometry() re-checks that reading on every run
# rather than leaving it as a comment that a future release of the volume
# could quietly falsify.
#
# Run with: Rscript data-raw/make_atlas.R

library(ggseg.extra)
library(ggseg.formats)

Sys.setenv(FREESURFER_HOME = "/Applications/freesurfer/7.4.1")

input_volume <- here::here("data-raw", "source", "MCALT_ADIR122.nii")

volume <- RNifti::readNifti(input_volume)
volume_array <- as.array(volume)
volume_idx <- sort(unique(as.integer(volume_array[volume_array > 0])))

xform <- RNifti::xform(volume)
centroids <- do.call(
  rbind,
  lapply(volume_idx, function(idx) {
    voxels <- which(volume_array == idx, arr.ind = TRUE)
    world <- xform %*% rbind(t(voxels - 1), 1)
    colMeans(t(world)[, 1:3, drop = FALSE])
  })
)
dimnames(centroids) <- list(as.character(volume_idx), c("x", "y", "z"))

accumbens <- c(21, 22)
hippocampus <- c(37, 38)
amygdala <- c(41, 42)
basal_ganglia <- 71:76
thalamus <- c(77, 78)
cerebellar_hemispheres <- 91:108
vermis <- 109:116
brainstem <- c(117, 118)

# The named groups above are anatomy, so they are asserted as anatomy. A
# centroid that has moved out of the box its group claims means the volume is
# no longer the one these indices were read from, and the atlas that would be
# built from it would be mislabelled rather than merely different.
check_group_geometry <- function(idx, what, x = NULL, y = NULL, z = NULL) {
  bounds <- list(x = x, y = y, z = z)
  for (axis in names(bounds)) {
    limits <- bounds[[axis]]
    if (is.null(limits)) {
      next
    }
    values <- centroids[as.character(idx), axis]
    outside <- values < limits[1] | values > limits[2]
    if (any(outside)) {
      cli::cli_abort(
        "{what} centroid{?s} outside the expected {axis} range
         {.val {limits}}: {.val {idx[outside]}} at {.val {round(values[outside], 1)}}",
        wrap = TRUE
      )
    }
  }
  invisible(idx)
}

# Both cerebellar groups sit in the posterior fossa: behind the brainstem
# centroid and below the tentorium. The vermis is additionally within a few
# millimetres of the midline, which is what makes it the vermis rather than
# a tenth pair of lobules.
check_group_geometry(
  cerebellar_hemispheres,
  "Cerebellar",
  y = c(-90, -35),
  z = c(-60, -10)
)
check_group_geometry(
  vermis,
  "Vermis",
  x = c(-5, 5),
  y = c(-90, -35),
  z = c(-60, -10)
)
check_group_geometry(brainstem, "Brainstem", x = c(-5, 5), y = c(-40, -15))
check_group_geometry(
  c(accumbens, hippocampus, amygdala, basal_ganglia, thalamus),
  "Deep grey",
  y = c(-25, 15),
  z = c(-25, 10)
)

# The vermis goes with the cerebellum rather than with the midline
# structures: it is cerebellar cortex, it is lobulated on the same I-X scheme
# as the hemispheres, and the SUIT flatmap the cerebellar pipeline projects
# onto carries it as its own midline strip. The brainstem goes with the
# subcortical structures instead: it is not cerebellar cortex, it has no
# place on a flatmap of the cerebellar surface, and a slice view is where
# FreeSurfer's aseg draws it too.
cerebellar <- c(cerebellar_hemispheres, vermis)
subcortical <- c(
  accumbens,
  hippocampus,
  amygdala,
  basal_ganglia,
  thalamus,
  brainstem
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
  type = dplyr::case_when(
    volume_idx %in% cerebellar ~ "cerebellar",
    volume_idx %in% subcortical ~ "subcortical",
    .default = "cortical"
  )
)

cli::cli_alert_info(
  "{sum(lut$type == 'cortical')} cortical, \\
   {sum(lut$type == 'subcortical')} subcortical, \\
   {sum(lut$type == 'cerebellar')} cerebellar labels"
)

# Steps 1-4 only. The wholebrain pipeline's own cerebellar step hands the
# volume to create_cerebellar_from_volume() unchanged, which samples it
# against the SUIT surfaces; MCALT is not in SUIT space, so the cerebellum is
# built below instead, after the MNI-to-SUIT deformation.
atlases <- create_wholebrain_from_volume(
  input_volume = input_volume,
  input_lut = lut,
  atlas_name = "mcalt",
  output_dir = "data-raw",
  registration = "header",
  skip_existing = TRUE,
  cleanup = FALSE,
  steps = 1:4
)

.mcalt_cortical <- atlas_smooth(
  atlas_simplify(atlases$cortical, keep = 0.2),
  smoothness = 0.4,
  method = "chaikin"
)

# The grey context and the structures are polished separately, because they
# are different kinds of shape. The structures are compact blobs traced off a
# voxel grid, and simplifying them hard and rounding what is left turns the
# staircase into something that reads as a nucleus. The context is a single
# slice of the whole cortical ribbon, and all of its interest is in the sulci
# and gyri: polished at the structures' rate the interhemispheric fissure, the
# sylvian slits and the temporal notches all round shut and it comes out a
# potato. It keeps nine tenths of its vertices instead, and is rounded at half
# the strength - enough to take the voxel staircase off the outer boundary,
# not enough to close a slit.
#
# Whichever way it is tuned, both passes stay on "chaikin": the default
# "close" is a morphological closing, and it fills every sulcus narrower than
# the smoothing distance whatever the keep is set to.
.mcalt_subcortical <- atlases$subcortical |>
  atlas_simplify(keep = 0.5, exclude = "^cortex") |>
  atlas_simplify(keep = 0.9, labels = "^cortex") |>
  atlas_smooth(smoothness = 0.4, method = "chaikin", exclude = "^cortex") |>
  atlas_smooth(smoothness = 0.2, method = "chaikin", labels = "^cortex")

# --- Cerebellum -------------------------------------------------------------
# The cerebellar pipeline projects onto the SUIT flatmap, so the parcels have
# to be in SUIT space first. MCALT is close enough to MNI152 for the SUIT
# deformation field to land: all 26 parcels survive the resample, and the
# flatmap comes out symmetric and lobular with the vermis as a midline strip.

cerebellar_mni <- tempfile(fileext = ".nii.gz")
cerebellar_masked <- array(0L, dim = dim(volume_array))
for (idx in cerebellar) {
  cerebellar_masked[volume_array == idx] <- idx
}
cerebellar_volume <- RNifti::asNifti(cerebellar_masked, reference = volume)
if (RNifti::orientation(cerebellar_volume) != "RAS") {
  RNifti::orientation(cerebellar_volume) <- "RAS"
}
RNifti::writeNifti(cerebellar_volume, cerebellar_mni)

cerebellar_suit <- here::here("data-raw", "mcalt", "cerebellar_suit.nii.gz")
transform_mni_to_suit(
  input_volume = cerebellar_mni,
  deformation_field = suit_deformation_field(template = "MNI152NLin6AsymC"),
  output_file = cerebellar_suit,
  interpolation = "nearest"
)

# transform_mni_to_suit() writes doubles; the reader wants label indices.
suit_volume <- RNifti::readNifti(cerebellar_suit, internal = FALSE)
suit_array <- as.array(suit_volume)
storage.mode(suit_array) <- "integer"
RNifti::writeNifti(
  RNifti::asNifti(suit_array, reference = suit_volume),
  cerebellar_suit
)

# The cerebellar reader takes the hemisphere from a Left/Right/Vermis prefix
# on the label, and MCALT's generic names carry none, so every lobule would
# land in one "midline" hemisphere. The prefix comes off the same centroids
# the groups were read from: the vermis is the midline group, and everything
# else is the side its centroid sits on.
cerebellar_lut <- lut[lut$type == "cerebellar", ]
cerebellar_lut$label <- paste(
  dplyr::case_when(
    cerebellar_lut$idx %in% vermis ~ "Vermis",
    centroids[as.character(cerebellar_lut$idx), "x"] < 0 ~ "Left",
    .default = "Right"
  ),
  cerebellar_lut$label,
  sep = "_"
)

.mcalt_cerebellar <- create_cerebellar_from_volume(
  input_volume = cerebellar_suit,
  input_lut = cerebellar_lut[, c("idx", "label", "R", "G", "B", "A")],
  atlas_name = "mcalt_cerebellar",
  output_dir = "data-raw/mcalt",
  skip_existing = FALSE,
  cleanup = FALSE
)

.mcalt_cerebellar <- atlas_smooth(
  atlas_simplify(.mcalt_cerebellar, keep = 0.2),
  smoothness = 0.4,
  method = "chaikin"
)

# The whole-volume palette spreads 122 hues over the colour wheel, so any 26
# consecutive indices come out as one narrow band of it. Re-spreading the
# hues across the cerebellar atlas alone makes its lobules tell apart.
cerebellar_labels <- atlas_labels(.mcalt_cerebellar)
cerebellar_hues <- seq(
  15,
  375,
  length.out = length(cerebellar_labels) + 1
)[seq_along(cerebellar_labels)]
set.seed(3)
.mcalt_cerebellar <- set_atlas_palette(
  .mcalt_cerebellar,
  stats::setNames(
    sample(grDevices::hcl(h = cerebellar_hues, c = 100, l = 65)),
    cerebellar_labels
  )
)

usethis::use_data(
  .mcalt_cortical,
  .mcalt_subcortical,
  .mcalt_cerebellar,
  overwrite = TRUE,
  compress = "xz",
  internal = TRUE
)
