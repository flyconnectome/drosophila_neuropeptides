# Load libraries
library(fafbseg)
library(tidyverse)
library(readr)
library(catmaid)

# Get the data we have already built
gt.nt.orig <- readr::read_csv(file = "/Users/GD/LMBD/Papers/synister/drosophila_neuropeptides/gt_np_data.csv")
extra <- readr::read_csv(file = "/Users/GD/LMBD/Papers/synister/drosophila_neuropeptides/gt_sources/extra.csv")

# Transmitters we care about
fast.nts <- c("acetylcholine", "gaba", "glutamate",
              "dopamine", "serotonin", "octopamine",
              "nitric oxide", "histamine", "tyramine", "glycine")
neg.fast.nts <- c("acetylcholine-negative", "gaba-negative", "glutamate-negative",
              "dopamine-negative", "serotonin-negative", "octopamine-negative",
              "nitric oxide-negative", "histamine-negative", "tyramine-negative", "glycine-negative",
              "no small-molecule transmitters","NA")
all.fast.nts <- c(fast.nts, neg.fast.nts)

# Function to process known_nt column
filter_words <- function(input_string, words_to_keep, invert = FALSE){
  words <- unlist(strsplit(input_string, ",|, |;|; |NA"))
  words <- gsub("^ | $","",words)
  words <- setdiff(words,c(" ",",",", ","",";","; "))
  if (invert){
    filtered_words <- words[! words %in% words_to_keep]
  }else{
    filtered_words <- words[words %in% words_to_keep]
  }
  paste(filtered_words, collapse = ", ")
}
simplify_nt <- function(input_string){
  words <- unlist(strsplit(input_string, ",|, |;|; "))
  words <- gsub("^ | $","",words)
  words <- sort(unique(words))
  words <- words[!words %in% c("NA",""," ")]
  paste(words, collapse = ", ")
}

# Query and organse flytable data, from midbrain and optic lobe tables
#ft <- fafbseg::flytable_query("select _id, root_id, root_630, root_783, supervoxel_id, proofread, status, pos_x, pos_y, pos_z, nucleus_id, soma_x, soma_y, soma_z, side, ito_lee_hemilineage, hartenstein_hemilineage, top_nt, flow, super_class, cell_class, cell_type, hemibrain_match, hemibrain_type, malecns_type, cb_type, root_duplicated, morphology_group, known_nt, known_nt_source, notes from info")
ft <- bancr::franken_meta()
ft$region <- 'midbrain'
ft.optic <- fafbseg::flytable_query("select * from optic")
ft.optic <- ft.optic[, intersect(colnames(ft.optic),
                                 colnames(ft))]
ft.optic <- ft.optic[!ft.optic$root_id %in% ft$root_id,]
ft.optic$region = 'optic_lobes'
ft.all <- plyr::rbind.fill(ft, ft.optic)
ft <- ft.all %>% dplyr::filter(!duplicated(root_id))
ft$species = 'adult_drosophila_melanogaster'

# Make cross typing sheet
ft.cross <- ft %>%
  tidyr::separate_longer_delim(hemibrain_type, delim = ", ") %>%
  tidyr::separate_longer_delim(hemibrain_type, delim = ",") %>%
  dplyr::mutate(cell_type = case_when(
    !is.na(cell_type) ~ cell_type,
    !is.na(hemibrain_type) ~ hemibrain_type,
    !is.na(cb_type) ~ cb_type,
    !is.na(morphology_group) ~ morphology_group,
    !is.na(malecns_type) ~ malecns_type,
    TRUE ~ cell_type
  )) %>%
  dplyr::distinct(cell_type, hemibrain_type, malecns_type, morphology_group, ito_lee_hemilineage, hartenstein_hemilineage, region) %>%
  dplyr::mutate(in_fafb = TRUE,
                in_hemibrain = !is.na(hemibrain_type),
                in_banc = 'to_be_found',
                in_mcns = !is.na(malecns_type),
                in_l1 = FALSE) %>%
  dplyr::arrange(ito_lee_hemilineage)
readr::write_csv(x = ft.cross, file = "/Users/GD/LMBD/Papers/synister/drosophila_neuropeptides/inst/extdata/cell_type_cross_matching.csv")

# Take only the entries with a known_nt column
ft.np <- ft %>%
  dplyr::mutate(cell_type = dplyr::case_when(
    !is.na(cell_type) ~ cell_type,
    !is.na(hemibrain_type) ~ hemibrain_type,
    !is.na(cb_type) ~ cb_type,
    !is.na(morphology_group) ~ morphology_group,
    TRUE ~ cell_type
  )) %>%
  dplyr::mutate(known_nt = dplyr::case_when(
    grepl("^LK",notes) ~ paste0(known_nt,"leucokinin"),
    TRUE ~ known_nt
  )) %>%
  dplyr::mutate(known_nt_source = dplyr::case_when(
    grepl("^LK",notes) ~ paste0(known_nt_source,"; Zandawala (immuno)"),
    TRUE ~ known_nt_source
  )) %>%
  dplyr::mutate(cell_type = dplyr::case_when(
    cell_type=="PI" ~ paste0("PI_",gsub("cell_type==(.+?)[,\n].*", "\\1", notes, perl=TRUE)),
    TRUE ~ cell_type
  )) %>%
  dplyr::select(cell_type, ito_lee_hemilineage, hemibrain_type, notes, known_nt, known_nt_source, species, region) %>%
  dplyr::filter(!is.na(known_nt), !known_nt%in%c(""," ","NA","unknown")) %>%
  tidyr::separate_longer_delim(c(known_nt, known_nt_source), delim = ";") %>%
  dplyr::rowwise() %>%
  dplyr::mutate(known_np = filter_words(known_nt, all.fast.nts, invert = TRUE)) %>%
  dplyr::ungroup() %>%
  dplyr::filter(known_np!="", grepl("\\(",known_nt_source)) %>%
  dplyr::rowwise() %>%
  dplyr::mutate(known_np_evidence = gsub("\\(|\\)",
                                         "",
                                         regmatches(known_nt_source, gregexpr("\\((.*?)\\)", known_nt_source))[[1]])) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(known_np_source = gsub("\\(.*?\\)", "", known_nt_source),
                known_np_source = gsub(" $", "", known_np_source),
                known_np_source = gsub("et al |et al,", "et al., ", known_np_source),
                known_np_source = gsub("^ ", "", known_np_source),
                known_np_source = gsub("\\)\\)", ")", known_np_source)) %>%
  tidyr::separate_longer_delim(cell_type, delim = ", ") %>%
  dplyr::arrange(cell_type, known_np, known_np_source, known_np_evidence) %>%
  dplyr::distinct(species, region, cell_type, ito_lee_hemilineage, known_np, known_np_source, known_np_evidence) %>%
  dplyr::rename(hemilineage=ito_lee_hemilineage) %>%
  dplyr::mutate(known_np_confidence = dplyr::case_when(
    known_np_evidence %in% c("immuno","immuno, intersection") ~ 4,
    known_np_evidence %in% c("transgenics","intersection","MCFO") ~ 3,
    known_np_evidence %in% c("TAPIN","RNAi","EASI-FISH") ~ 2,
    known_np_evidence %in% c("scRNA-seq","RT-PCR", "immuno, unsure", "MCFO, unsure") ~ 1,
    known_np_evidence %in% c("scRNA-seq, unsure") ~ 0,
    TRUE ~ 0
  ))
ft.np <- plyr::rbind.fill(ft.np,extra)

# Turn into a matrix
ft.np.m <- ft.np %>%
  tidyr::separate_longer_delim(known_np, delim = ", ") %>%
  dplyr::distinct(cell_type, known_np, known_np_source, .keep_all = TRUE) %>%
  dplyr::filter(!is.na(cell_type), !is.na(known_np)) %>%
  dplyr::mutate(value = dplyr::case_when(
    grepl("negative",known_np) ~ -1,
    TRUE ~ 1
  )) %>%
  dplyr::mutate(known_np = gsub("-negative.*","",known_np)) %>%
  dplyr::distinct() %>%
  tidyr::spread(key = known_np, value = value, fill = 0) %>%
  as.data.frame()

# Fix column names
colnames(ft.np.m) <- gsub(" ","_",colnames(ft.np.m))
colnames(ft.np.m) <- tolower(colnames(ft.np.m))

# Order the data appropriately
meta.cols <- c("species", "region", "hemilineage", "cell_type",
               "known_np_source", "known_np_evidence", "known_np_confidence")
nps <- sort(setdiff(colnames(ft.np.m),meta.cols))
gt.nt <- ft.np.m
gt.nt[is.na(gt.nt)] <- 0
column.order <-c(meta.cols,
                 nps)
gt.nt <- gt.nt[,column.order]
gt.nt.new <- gt.nt

# Combine old and new
# gt.nt.new <- rbind(gt.nt.orig, gt.nt) %>%
#   dplyr::distinct()
# dupes <- duplicated(paste0(gt.nt.new$cell_type,gt.nt.new$known_np_source))

# Leave unknown hemilinegaes blank
gt.nt.new$hemilineage[is.na(gt.nt.new$hemilineage)] <- ""
gt.nt.new$known_np_source[is.na(gt.nt.new$known_np_source)] <- ""
gt.nt.new$known_np_evidence[is.na(gt.nt.new$known_np_evidence)] <- ""
gt.nt.new$known_np_evidence[is.na(gt.nt.new$known_np_confidence)] <- 0

# Save data
readr::write_csv(x =  ft.np,
                 file = "/Users/GD/LMBD/Papers/synister/drosophila_neuropeptides/gt_sources/bates_2024/202409-gt_np_data.csv")
readr::write_csv(x = gt.nt.new,
                 file = "/Users/GD/LMBD/Papers/synister/drosophila_neuropeptides/gt_np_data.csv")







