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

# Function to process neurotransmitter_verified column
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
#ft <- fafbseg::flytable_query("select _id, root_id, root_630, root_783, supervoxel_id, proofread, status, pos_x, pos_y, pos_z, nucleus_id, soma_x, soma_y, soma_z, side, hemilineage, hartenstein_hemilineage, top_nt, flow, super_class, cell_class, cell_type, hemibrain_match, hemibrain_type, malecns_type, cb_type, root_duplicated, morphology_group, neurotransmitter_verified, neurotransmitter_verified_source, notes from info")
ft.all <- bancr::franken_meta()
#ft$region <- 'midbrain'
# ft.optic <- fafbseg::flytable_query("select * from optic")
# ft.optic <- ft.optic[, intersect(colnames(ft.optic),
#                                  colnames(ft))]
# ft.optic <- ft.optic[!ft.optic$root_id %in% ft$root_id,]
# ft.optic$region = 'optic_lobe'
# ft.all <- plyr::rbind.fill(ft, ft.optic)
ft <- ft.all %>% dplyr::filter(!duplicated(neuron_id))
ft$species = 'adult_drosophila_melanogaster'

# Make cross typing sheet
ft.cross <- ft %>%
  tidyr::separate_longer_delim(hemibrain_type, delim = ", ") %>%
  tidyr::separate_longer_delim(hemibrain_type, delim = ",") %>%
  dplyr::mutate(cell_type = case_when(
    !is.na(cell_type) ~ cell_type,
    !is.na(hemibrain_type) ~ hemibrain_type,
    !is.na(morphology_group) ~ morphology_group,
    TRUE ~ cell_type
  )) %>%
  dplyr::distinct(cell_type, hemibrain_type, hemilineage, region) %>%
  dplyr::arrange(hemilineage)
readr::write_csv(x = ft.cross, file = "/Users/GD/LMBD/Papers/synister/drosophila_neuropeptides/inst/extdata/cell_type_cross_matching.csv")

# Take only the entries with a neurotransmitter_verified column
ft.np <- ft %>%
  dplyr::mutate(cell_type = dplyr::case_when(
    !is.na(cell_type) ~ cell_type,
    !is.na(hemibrain_type) ~ hemibrain_type,
    !is.na(morphology_group) ~ morphology_group,
    TRUE ~ cell_type
  )) %>%
  dplyr::mutate(neurotransmitter_verified = dplyr::case_when(
    grepl("^LK",notes) ~ paste0(neurotransmitter_verified,"leucokinin"),
    TRUE ~ neurotransmitter_verified
  )) %>%
  dplyr::mutate(neurotransmitter_verified_source = dplyr::case_when(
    grepl("^LK",notes) ~ paste0(neurotransmitter_verified_source,"; Zandawala (immuno)"),
    TRUE ~ neurotransmitter_verified_source
  )) %>%
  dplyr::mutate(cell_type = dplyr::case_when(
    cell_type=="PI" ~ paste0("PI_",gsub("cell_type==(.+?)[,\n].*", "\\1", notes, perl=TRUE)),
    TRUE ~ cell_type
  )) %>%
  dplyr::select(cell_type, hemilineage, hemibrain_type, notes, neurotransmitter_verified, neurotransmitter_verified_source, species, region) %>%
  dplyr::filter(!is.na(neurotransmitter_verified), !neurotransmitter_verified%in%c(""," ","NA","unknown")) %>%
  tidyr::separate_longer_delim(c(neurotransmitter_verified, neurotransmitter_verified_source), delim = ";") %>%
  dplyr::rowwise() %>%
  dplyr::mutate(neuropeptide_verified = filter_words(neurotransmitter_verified, all.fast.nts, invert = TRUE)) %>%
  dplyr::ungroup() %>%
  dplyr::filter(neuropeptide_verified!="", grepl("\\(",neurotransmitter_verified_source)) %>%
  dplyr::rowwise() %>%
  dplyr::mutate(neuropeptide_verified_evidence = gsub("\\(|\\)",
                                         "",
                                         regmatches(neurotransmitter_verified_source, gregexpr("\\((.*?)\\)", neurotransmitter_verified_source))[[1]])) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(neuropeptide_verified_source = gsub("\\(.*?\\)", "", neurotransmitter_verified_source),
                neuropeptide_verified_source = gsub(" $", "", neuropeptide_verified_source),
                neuropeptide_verified_source = gsub("et al |et al,", "et al., ", neuropeptide_verified_source),
                neuropeptide_verified_source = gsub("^ ", "", neuropeptide_verified_source),
                neuropeptide_verified_source = gsub("\\)\\)", ")", neuropeptide_verified_source)) %>%
  tidyr::separate_longer_delim(cell_type, delim = ", ") %>%
  dplyr::arrange(cell_type, neuropeptide_verified, neuropeptide_verified_source, neuropeptide_verified_evidence) %>%
  dplyr::distinct(species, region, cell_type, hemilineage, neuropeptide_verified, neuropeptide_verified_source, neuropeptide_verified_evidence) %>%
  dplyr::rename(hemilineage=hemilineage) %>%
  dplyr::mutate(neuropeptide_verified_confidence = dplyr::case_when(
    neuropeptide_verified_evidence %in% c("immuno","immuno, intersection") ~ 4,
    neuropeptide_verified_evidence %in% c("transgenics","intersection","MCFO") ~ 3,
    neuropeptide_verified_evidence %in% c("TAPIN","RNAi","EASI-FISH") ~ 2,
    neuropeptide_verified_evidence %in% c("scRNA-seq","RT-PCR", "immuno, unsure", "MCFO, unsure") ~ 1,
    neuropeptide_verified_evidence %in% c("scRNA-seq, unsure") ~ 0,
    TRUE ~ 0
  ))
ft.np <- plyr::rbind.fill(ft.np,extra)

# Turn into a matrix
ft.np.m <- ft.np %>%
  tidyr::separate_longer_delim(neuropeptide_verified, delim = ", ") %>%
  dplyr::distinct(cell_type, neuropeptide_verified, neuropeptide_verified_source, .keep_all = TRUE) %>%
  dplyr::filter(!is.na(cell_type), !is.na(neuropeptide_verified)) %>%
  dplyr::mutate(value = dplyr::case_when(
    grepl("negative",neuropeptide_verified) ~ -1,
    TRUE ~ 1
  )) %>%
  dplyr::mutate(neuropeptide_verified = gsub("-negative.*","",neuropeptide_verified)) %>%
  dplyr::distinct() %>%
  tidyr::spread(key = neuropeptide_verified, value = value, fill = 0) %>%
  as.data.frame()

# Fix column names
colnames(ft.np.m) <- gsub(" ","_",colnames(ft.np.m))
colnames(ft.np.m) <- tolower(colnames(ft.np.m))

# Order the data appropriately
meta.cols <- c("species", "region", "hemilineage", "cell_type",
               "neuropeptide_verified_source",
               "neuropeptide_verified_evidence",
               "neuropeptide_verified_confidence")
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
# dupes <- duplicated(paste0(gt.nt.new$cell_type,gt.nt.new$neuropeptide_verified_source))

# Leave unknown hemilinegaes blank
gt.nt.new$hemilineage[is.na(gt.nt.new$hemilineage)] <- ""
gt.nt.new$neuropeptide_verified_source[is.na(gt.nt.new$neuropeptide_verified_source)] <- ""
gt.nt.new$neuropeptide_verified_evidence[is.na(gt.nt.new$neuropeptide_verified_evidence)] <- ""
gt.nt.new$neuropeptide_verified_evidence[is.na(gt.nt.new$neuropeptide_verified_confidence)] <- 0

# Save data
readr::write_csv(x =  ft.np,
                 file = "/Users/GD/LMBD/Papers/synister/drosophila_neuropeptides/gt_sources/bates_2024/202602-gt_np_data.csv")
readr::write_csv(x = gt.nt.new,
                 file = "/Users/GD/LMBD/Papers/synister/drosophila_neuropeptides/gt_np_data.csv")
