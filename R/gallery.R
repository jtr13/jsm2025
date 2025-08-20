# need to manually save page: https://exts.ggplot2.tidyverse.org/gallery/
library(rvest)

df <- read_html("raw_data/exts.ggplot2.tidyverse.org.html")

package_names <- df |>
  html_elements("div.card-content") |> 
  html_elements("span.card-title") |> 
  html_text() |> 
  sort()
writeLines(package_names, con = "generated_data/gallery_packages.txt")
