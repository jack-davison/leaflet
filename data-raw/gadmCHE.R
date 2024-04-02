
# https://gadm.org/download_country.html
# switzerland
# rds
# level 1
gadmCHE <- geodata::gadm("CHE", level = 1, path = ".")

gadmCHE$NAME_1 <- iconv(gadmCHE$NAME_1, "UTF-8", "ASCII//TRANSLIT")
gadmCHE$VARNAME_1 <- iconv(gadmCHE$VARNAME_1, "UTF-8", "ASCII//TRANSLIT")

gadmCHE <- sf::st_as_sf(gadmCHE)

usethis::use_data(gadmCHE, overwrite = TRUE)

print(tools::showNonASCIIfile("data/gadmCHE.rda"))
