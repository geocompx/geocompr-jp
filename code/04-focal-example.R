library(tmap)
library(sf)
library(terra)
library(grid)
elev = rast(system.file("raster/elev.tif", package = "spData"))
elev[1, 1] = 0

poly_window = rbind(c(-1.5, 0), c(0,0), c(0, 1.5), c(-1.5, 1.5), c(-1.5, 0)) |>
  list() |>
  st_polygon() |>
  st_sfc() |>
  st_sf(data.frame(id = 1), geometry = _, crs = "EPSG:4326")

poly_target = rbind(c(-1, 0.5), c(-0.5, 0.5), c(-0.5, 1), c(-1, 1), c(-1, 0.5)) |>
  list() |>
  st_polygon() |>
  st_sfc() |>
  st_sf(data.frame(id = 1), geometry = _, crs = "EPSG:4326")

polys = st_as_sf(terra::as.polygons(elev, na.rm = FALSE, dissolve = FALSE))
r_focal = focal(elev, w = matrix(1, nrow = 3, ncol = 3), fun = min)
poly_focal = st_as_sf(terra::as.polygons(r_focal, na.rm = FALSE, dissolve = FALSE))
poly_focal$focal_min[is.nan(poly_focal$focal_min)] = NA
poly_focal$focal_min2 = as.character(poly_focal$focal_min)
poly_focal$focal_min2[is.na(poly_focal$focal_min2)] = "NA"

tm1 = tm_shape(polys) +
  tm_polygons(fill = "elev", fill.scale = tm_scale_continuous(), lwd = 0.5) +
  tm_text(text = "elev") +
  tm_shape(poly_target) +
  tm_borders(lwd = 3, col = "orange") +
  tm_shape(poly_window) +
  tm_borders(lwd = 6, col = "orange") +
  tm_layout(frame = FALSE, legend.show = FALSE)

tm2 = tm_shape(poly_focal) +
  tm_polygons(fill = "focal_min",  fill.scale = tm_scale_continuous(), lwd = 0.5) +
  tm_text(text = "focal_min2") +
  tm_shape(poly_target) +
  tm_borders(lwd = 3, col = "orange") +
  tm_layout(frame = FALSE, legend.show = FALSE)

png(filename = "images/04_focal_example.png", width = 950, height = 555)
tmap_arrange(tm1, tm2)
grid.polyline(x = c(0.255, 0.59), y = c(0.685, 0.685), 
              arrow = arrow(length = unit(0.2, "inches")), 
              gp = gpar(lwd = 2))
dev.off()
