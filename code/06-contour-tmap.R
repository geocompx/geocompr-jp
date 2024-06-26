library(tmap)
library(sf)
library(terra)
dem = rast(system.file("raster/dem.tif", package = "spDataLarge"))
# create hillshade
hs = shade(slope = terrain(dem, "slope", unit = "radians"), 
           aspect = terrain(dem, "aspect", unit = "radians"))
# https://github.com/rspatial/terra/issues/948#issuecomment-1356226265
# h = shade(slope = terrain(dem, "slope", unit = "radians"),
#           aspect = terrain(dem, "aspect", unit = "radians"),
#           angle = c(45, 45, 45), direction = c(0, 45, 315))
# h = Reduce(mean, h)
# create contour
cn = st_as_sf(as.contour(dem))

# toDo: jn
# tm_iso does not exist
tm1 = tm_shape(hs) +
  tm_grid(col = "black", n.x = 2, n.y = 2, labels.rot = c(0, 90)) +
  tm_raster(col.scale = tm_scale(values = gray(0:100 / 100), n = 100)) +
  tm_shape(dem) +
  tm_raster(col_alpha = 0.6, col.scale = tm_scale(values = hcl.colors(25, "Geyser"))) +
  tm_shape(cn) +
  tm_lines(col = "white") +
  tm_text("level") +
  #tm_shape(cn) +
  #tm_iso("level", col = "white") +
  tm_layout(outer.margins = c(0.04, 0.04, 0.02, 0.02), frame = FALSE, legend.show = FALSE)

tmap_save(tm1, "images/05-contour-tmap.png", height = 1000, width = 1000)
