# ggsegMcalt 1.0.1.9001

The atlases are rebuilt from source against the current ggseg.extra pipeline,
and the cerebellum is split out into one of its own.

## Atlases

- **The cerebellum is its own atlas, `mcalt_cerebellar()`.** MCALT divides it
  into nine lobule pairs and an eight-part vermis, which is a cerebellar
  parcellation rather than deep grey matter, so it now goes through the SUIT
  flatmap pipeline instead of being drawn as 26 blobs across the subcortical
  slices. The vermis goes with it, being cerebellar cortex lobulated on the
  same scheme as the hemispheres; the brain stem (`region_0117`/`region_0118`)
  stays in `mcalt_subcortical()`, which has no flatmap to sit on and is where
  FreeSurfer's aseg draws it too. `mcalt_subcortical()` is 16 structures now.
- The lobules carry a hemisphere again. The cerebellar reader takes the side
  from a `Left`/`Right`/`Vermis` prefix, and MCALT's generic names have none,
  so the prefix is set from each label's centroid.

## Regions

- **All 122 MCALT ADIR122 labels are now in the atlas**, up from 96. The 26
  that were previously dropped are the pallidum and putamen
  (`region_0073`--`region_0076`), the cerebellar hemispheres and vermis
  (`region_0093`--`region_0116`, minus those already present, now in
  `mcalt_cerebellar()`) and `region_0118`.
- **`region_0042` is an amygdala again.** The pipeline used to write
  subcortical structures onto the FreeSurfer brain-outline indices, and
  MCALT's index 42 is its right amygdala, so it rendered as the entire right
  hemisphere at 19,688 vertices. The largest mesh is now `region_0091` at
  1,355 vertices.
- **The cortical/subcortical split comes from a lookup table.** MCALT
  publishes no label names, so `data-raw/make_atlas.R` builds a table with
  the generic `region_NNNN` names, a colour per index and a `type` column,
  each index placed by its centroid in the volume, and every group's
  centroids re-checked against the anatomy its name claims on each run.
  `region_0037/0038` (the hippocampi) move to the subcortical atlas;
  `region_0119/0120`, `region_0123/0124` and `region_0126` move to the
  cortical atlas.

## Rendering

- **Regions have colours.** Without a lookup table the cortical palette was
  entirely `NA` and the subcortical palette entirely black. Each structure
  now has a distinct hue.
- The cortical surface no longer has holes, and the medial wall is drawn as
  grey context rather than as a region: `unknown` is in the geometry but not
  in the atlas core or palette.
- **The grey context keeps its sulci.** The subcortical atlas used to be
  simplified and rounded in one pass, which closed the interhemispheric
  fissure, the sylvian slits and the temporal notches and left the backdrop a
  smooth blob. The context now keeps nine tenths of its vertices and is
  rounded at half the strength the structures are, which takes the voxel
  staircase off the outline without closing a sulcus.
- Subcortical slabs are framed on the label bounding box, and the geometry is
  explicitly simplified and smoothed, which cuts the cortical atlas from
  29,723 to 8,898 vertices. The subcortical atlas holds 4,626 across its 16
  structures and the cerebellar one 2,521 across its 26.

## Tests

- The test file called `mcalt()`, a function this package has never exported,
  so every test in it errored. It now exercises `mcalt_cortical()`,
  `mcalt_subcortical()` and `mcalt_cerebellar()`, and checks where the vermis
  and the brain stem ended up.
