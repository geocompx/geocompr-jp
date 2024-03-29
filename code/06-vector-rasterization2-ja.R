library(tmap)

if (!exists("raster_template2")) {
  library(sf)
  library(terra)
  library(spData)
  library(spDataLarge)
  california = dplyr::filter(us_states, NAME == "California")
  california_borders = st_cast(california, "MULTILINESTRING")
  raster_template2 = rast(ext(california), resolution = 0.5,
                          crs = crs(california))
  
  california_raster1 = rasterize(vect(california_borders), raster_template2,
                                 touches = TRUE)
  california_raster2 = rasterize(vect(california), raster_template2)
}

california_raster_centr = st_as_sf(as.polygons(raster_template2))
california_raster_centr = st_centroid(california_raster_centr)

r1po = tm_shape(california_raster1) + 
  tm_raster(col.legend = tm_legend("Values: "),
            col.scale = tm_scale(values = "#b6d8fc")) + 
  tm_shape(california_raster_centr) +
  tm_symbols(shape = 20, col = "black", size = 0.2) + 
  tm_shape(california) + tm_borders() + 
  tm_title("A. 線のラスタ化") + 
  tm_layout(legend.show = FALSE, frame = FALSE)

r2po = tm_shape(california_raster2) +
  tm_raster(col.legend = tm_legend("Values: "),
            col.scale = tm_scale(values = "#b6d8fc")) + 
  tm_shape(california_raster_centr) + 
  tm_symbols(shape = 20, col = "black", size = 0.2) + 
  tm_shape(california) + tm_borders() + 
  tm_title("B. ポリゴンのラスタ化")  + 
  tm_layout(legend.show = FALSE, frame = FALSE)

tmap_arrange(r1po, r2po, ncol = 2)