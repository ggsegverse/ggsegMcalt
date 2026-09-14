atlases <- list(
  mcalt_cortical = mcalt_cortical(),
  mcalt_subcortical = mcalt_subcortical()
)

describe("mcalt atlas structure", {
  it("is a valid ggseg_atlas object", {
    for (atlas in atlases) {
      expect_s3_class(atlas, "ggseg_atlas")
      expect_true(is_ggseg_atlas(atlas))
    }
  })

  it("has required core columns", {
    for (atlas in atlases) {
      expect_true(all(c("hemi", "region", "label") %in% names(atlas$core)))
    }
  })

  it("has valid hemisphere values", {
    for (atlas in atlases) {
      hemis <- unique(atlas$core$hemi)
      expect_true(all(hemis[!is.na(hemis)] %in% c("left", "right")))
    }
  })

  it("has atlas name and type", {
    expect_equal(atlases$mcalt_cortical$type, "cortical")
    expect_equal(atlases$mcalt_subcortical$type, "subcortical")
    for (atlas in atlases) {
      expect_true(nchar(atlas$atlas) > 0)
    }
  })

  it("has non-empty core", {
    expect_equal(nrow(atlases$mcalt_cortical$core), 80)
    expect_equal(nrow(atlases$mcalt_subcortical$core), 42)
  })
})

describe("mcalt 3D rendering support", {
  it("has a mesh per subcortical structure", {
    meshes <- atlases$mcalt_subcortical$data$meshes
    expect_equal(nrow(meshes), nrow(atlases$mcalt_subcortical$core))
  })

  it("has no mesh large enough to be a whole hemisphere", {
    meshes <- atlases$mcalt_subcortical$data$meshes
    vertices <- vapply(meshes$mesh, function(x) nrow(x$vertices), numeric(1))
    expect_lt(max(vertices), 5000)
  })
})

describe("mcalt 2D plotting", {
  it("can be plotted with ggseg", {
    for (atlas in atlases) {
      p <- ggplot2::ggplot() + ggseg::geom_brain(atlas = atlas)
      expect_s3_class(p, "gg")
    }
  })

  it("can be plotted with region fill", {
    for (atlas in atlases) {
      p <- ggplot2::ggplot() +
        ggseg::geom_brain(
          atlas = atlas,
          mapping = ggplot2::aes(fill = region)
        )
      expect_s3_class(p, "gg")
    }
  })
})

describe("mcalt data quality", {
  it("has unique labels per hemisphere", {
    for (atlas in atlases) {
      by_hemi <- split(atlas$core$label, atlas$core$hemi)
      for (labels in by_hemi) {
        labels <- labels[!is.na(labels)]
        expect_equal(length(labels), length(unique(labels)))
      }
    }
  })

  it("has no empty region names", {
    for (atlas in atlases) {
      regions <- atlas$core$region
      expect_true(all(nchar(regions[!is.na(regions)]) > 0))
    }
  })

  it("has a valid hex colour for every region", {
    for (atlas in atlases) {
      expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", atlas$palette)))
    }
  })

  it("keeps context geometry out of the core and palette", {
    for (atlas in atlases) {
      expect_false(any(grepl("unknown|cortex_", atlas$core$label)))
      expect_false(any(grepl("unknown|cortex_", names(atlas$palette))))
    }
  })
})
