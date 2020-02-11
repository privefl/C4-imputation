library(bigsnpr)

obj.bed <- bed(download_1000G("tmp-data"))

map_mhc <- dplyr::filter(obj.bed$map, chromosome == 6,
                         dplyr::between(physical.pos, 24e6, 34e6))
write(map_mhc$marker.ID, tmp <- tempfile())

system(glue::glue(
  "{download_plink('tmp-data')}",
  " --bfile {obj.bed$prefix}",
  " --extract {tmp}",
  " --recode vcf bgz",
  " --out tmp-data/1000G-MHC"
))
