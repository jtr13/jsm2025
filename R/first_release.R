
# Load tools package (should be available in base R)
library(tools)
library(tidyverse)

# Get current package metadata
db <- CRAN_package_db()

gallery_pkgs <- readLines("generated_data/gallery_packages.txt")

gg_pkgs <- db[grepl("^(gg|GG)", db$Package),] |> 
  mutate(lots_of_info = paste(Title, Description, Depends, Imports, Suggests))

not_gg <- gg_pkgs |>  
  filter(!grepl("ggplot2", lots_of_info)) |> 
  pull(Package)

gg_pkgs <- gg_pkgs |> 
  filter(grepl("ggplot2", lots_of_info)) |> 
  pull(Package)

combined <- data.frame(Package = unique(c(gallery_pkgs, gg_pkgs))) |> left_join(db) |> 
  select(package = Package, cran_publish_date = Published, authors = `Authors@R`) |> 
  mutate(cran_publish_date = as.Date(cran_publish_date))

# Get archive metadata (list of data frames)
archive_db <- CRAN_archive_db()

# Extract earliest archive date per package
archive_earliest <- lapply(archive_db, function(df) {
  as.Date(min(df$mtime))
})

# Turn into data frame
archive_df <- tibble(
  package = names(archive_earliest),
  archive_date = as.Date(unlist(archive_earliest))
) 

gg_archive_pkgs <- archive_df |> 
  filter(str_detect(package, "^(gg|GG)")) |> 
  filter(!(package %in% not_gg)) |> 
  pull(package)

archive_df <- archive_df |> 
  filter(package %in% c(gallery_pkgs, gg_archive_pkgs))


# Merge archive dates with current data
gg_all <- merge(combined, archive_df, by = "package", all = TRUE)

# Compute earliest known release date
gg_all$first_release <- pmin(gg_all$cran_publish_date, gg_all$archive_date, na.rm = TRUE)

gg_all <- gg_all |> 
  mutate(in_gallery = ifelse(package %in% gallery_pkgs, TRUE, FALSE))

# View first few
head(gg_all[order(gg_all$first_release), ], 20)

write_csv(gg_all, file = "generated_data/gg_packages_first_release.csv")

writeLines(not_gg, con = "generated_data/gg_not_ggplot2.txt")




