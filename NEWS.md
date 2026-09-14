# ggsegMcalt 1.1.0

Both atlases are rebuilt from source against the current ggseg.extra pipeline.

## Regions

- **All 122 MCALT ADIR122 labels are now in the atlas**, up from 96. The 26
  that were previously dropped are the pallidum and putamen
  (`region_0073`--`region_0076`), the cerebellar hemispheres and vermis
  (`region_0093`--`region_0116`, minus those already present) and
  `region_0118`.
- **`region_0042` is an amygdala again.** The pipeline used to write
  subcortical structures onto the FreeSurfer brain-outline indices, and
  MCALT's index 42 is its right amygdala, so it rendered as the entire right
  hemisphere at 19,688 vertices. The largest mesh is now `region_0091` at
  1,355 vertices.
- **The cortical/subcortical split comes from a lookup table.** MCALT
  publishes no label names, so `data-raw/make_atlas.R` builds a table with
  the generic `region_NNNN` names, a colour per index and a `type` column,
  each index placed by its centroid in the volume. `region_0037/0038` (the
  hippocampi) move to the subcortical atlas; `region_0119/0120`,
  `region_0123/0124` and `region_0126` move to the cortical atlas.

## Rendering

- **Regions have colours.** Without a lookup table the cortical palette was
  entirely `NA` and the subcortical palette entirely black. Each structure
  now has a distinct hue.
- The cortical surface no longer has holes, and the medial wall is drawn as
  grey context rather than as a region: `unknown` is in the geometry but not
  in the atlas core or palette.
- Subcortical slabs are framed on the label bounding box, and the geometry is
  explicitly simplified and smoothed, which cuts the cortical atlas from
  29,723 to 8,898 vertices; the subcortical atlas holds 7,827 vertices across
  more than twice as many structures.

## Tests

- The test file called `mcalt()`, a function this package has never exported,
  so every test in it errored. It now exercises `mcalt_cortical()` and
  `mcalt_subcortical()`.
