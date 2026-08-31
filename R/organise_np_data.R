# Load libraries
library(fafbseg)
library(tidyverse)
library(readr)
library(catmaid)

# Use repo-root paths so the script runs anywhere the repo is cloned.
repo_root <- tryCatch(
  rprojroot::find_rstudio_root_file(),
  error = function(e) here::here())
gt_path    <- file.path(repo_root, "gt_np_data.csv")
extra_path <- file.path(repo_root, "gt_sources", "extra.csv")
zandawala  <- file.path(repo_root, "gt_sources", "zandawala_2024",
                         "neuropeptide_meta.csv")

# Build a Symbol→lowercase column-header map from the Zandawala 2024
# meta CSV. Used to canonicalise peptide column names in gt_np_data.csv
# regardless of the casing in franken_meta.
np_meta <- readr::read_csv(zandawala, show_col_types = FALSE)
np_symbol_to_col <- setNames(tolower(np_meta$Symbol), np_meta$Symbol)
# Add aliases for non-Zandawala FlyBase peptides we know appear, and for the
# spellings curators actually type. Without these, one peptide becomes several
# columns: "dNPF" and "NPF" are the same gene product, as are "Hugin"/"Hug",
# "Tachykinin"/"Tk" and "dArc1"/"Arc1".
np_symbol_to_col <- c(np_symbol_to_col,
                       Spab = "spab", Amn = "amn", Arc1 = "arc1",
                       Thyrostimulin = "thyrostimulin",
                       dNPF = "npf", dArc1 = "arc1", Hugin = "hug",
                       Tachykinin = "tk", Leucokinin = "lk")

# Canonicalise ONE peptide name to its column header. Matching is
# case-insensitive because the annotation layer is hand-typed ("AstC", "Astc",
# "ASTC" all occur); anything unrecognised falls through as its own lower-case
# column rather than being dropped, so a genuinely new peptide is still visible.
canonical_peptide <- function(x) {
  x <- trimws(x)
  key <- match(tolower(x), tolower(names(np_symbol_to_col)))
  out <- ifelse(is.na(key), tolower(x), unname(np_symbol_to_col)[key])
  out[is.na(x)] <- NA_character_
  out
}

# Get the data we have already built (optional — only used for the
# legacy union step; safe to skip if missing)
gt.nt.orig <- if (file.exists(gt_path))
  readr::read_csv(gt_path, show_col_types = FALSE) else NULL
extra <- if (file.exists(extra_path))
  readr::read_csv(extra_path, show_col_types = FALSE) else NULL

# Normalise the hand-curated fields that key every downstream join.
#
#  * cell_type: hand-entered rows have arrived carrying a trailing NON-BREAKING
#    SPACE (U+00A0). trimws() does not strip U+00A0, so "MNad03 " survives as a
#    key distinct from "MNad03", splits one cell type across two rows of
#    gt_np_data.csv, and can never match a connectome cell_type. Convert U+00A0 to a
#    plain space, then trim.
#  * region: use one spelling per region. "vnc" and "ventral_nerve_cord" were both in
#    use for the same nerve-cord rows, so anything selecting VNC ground truth by region
#    silently saw only half of it.
normalise_gt_fields <- function(df) {
  if (is.null(df)) return(df)
  if ("cell_type" %in% names(df))
    df$cell_type <- trimws(gsub(" ", " ", df$cell_type))
  if ("region" %in% names(df)) {
    r <- trimws(as.character(df$region))
    df$region <- ifelse(r %in% "vnc", "ventral_nerve_cord", r)
  }
  df
}
extra <- normalise_gt_fields(extra)

# Transmitters we care about (kept as defensive filter only — the
# franken_meta NT/NP split (May 2026) means peptides should NOT appear
# in `neurotransmitter_verified`, but we double-check below).
fast.nts <- c("acetylcholine", "gaba", "glutamate",
              "dopamine", "serotonin", "octopamine",
              "nitric oxide", "histamine", "tyramine", "glycine")
neg.fast.nts <- c("acetylcholine-negative", "gaba-negative", "glutamate-negative",
              "dopamine-negative", "serotonin-negative", "octopamine-negative",
              "nitric oxide-negative", "histamine-negative", "tyramine-negative", "glycine-negative",
              "no small-molecule transmitters","NA")
all.fast.nts <- c(fast.nts, neg.fast.nts)

# Function to process verified-source columns
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
# READ THE LIVE ANNOTATION LAYER, NOT THE FROZEN SNAPSHOT.
# bancr::franken_meta() defaults to source = "gcs", which serves a periodically
# refreshed feather export. Curation happens in SeaTable (base `cns_meta`, tables
# `fafb` and `manc`), so a bare franken_meta() rebuilds the ground truth from
# whatever the last export happened to contain and silently misses every
# annotation entered since -- which is the only reason to rebuild at all.
# Needs $BANCTABLE_TOKEN.
ft.all <- bancr::franken_meta(source = "seatable", base = "cns_meta")
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
extdata_dir <- file.path(repo_root, "inst", "extdata")
dir.create(extdata_dir, showWarnings = FALSE, recursive = TRUE)
readr::write_csv(x = ft.cross,
                 file = file.path(extdata_dir,
                   "cell_type_cross_matching.csv"))

# Take only the entries with a neuropeptide_verified column.
#
# Post May-2026 franken split: peptide entries live in
# `neuropeptide_verified` and their evidence in
# `neuropeptide_verified_source`. We no longer need to parse them out
# of `neurotransmitter_verified`.
ft.np <- ft %>%
  dplyr::mutate(cell_type = dplyr::case_when(
    !is.na(cell_type) ~ cell_type,
    !is.na(hemibrain_type) ~ hemibrain_type,
    !is.na(morphology_group) ~ morphology_group,
    TRUE ~ cell_type
  )) %>%
  # LK-in-notes legacy hint: still useful for neurons annotated only
  # in `notes` (not yet promoted into neuropeptide_verified).
  dplyr::mutate(neuropeptide_verified = dplyr::case_when(
    grepl("^LK", notes) & (is.na(neuropeptide_verified) | neuropeptide_verified == "") ~ "Lk",
    grepl("^LK", notes) & !grepl("Lk|leucokinin", neuropeptide_verified) ~ paste0(neuropeptide_verified, ", Lk"),
    TRUE ~ neuropeptide_verified
  )) %>%
  dplyr::mutate(neuropeptide_verified_source = dplyr::case_when(
    grepl("^LK", notes) & (is.na(neuropeptide_verified_source) | neuropeptide_verified_source == "") ~ "Zandawala (immuno)",
    grepl("^LK", notes) & !grepl("Zandawala", neuropeptide_verified_source) ~ paste0(neuropeptide_verified_source, "; Zandawala (immuno)"),
    TRUE ~ neuropeptide_verified_source
  )) %>%
  dplyr::mutate(cell_type = dplyr::case_when(
    cell_type=="PI" ~ paste0("PI_",gsub("cell_type==(.+?)[,\n].*", "\\1", notes, perl=TRUE)),
    TRUE ~ cell_type
  )) %>%
  dplyr::select(cell_type, hemilineage, hemibrain_type, notes,
                 neuropeptide_verified, neuropeptide_verified_source,
                 species, region) %>%
  dplyr::filter(!is.na(neuropeptide_verified),
                 !neuropeptide_verified %in% c(""," ","NA","unknown")) %>%
  tidyr::separate_longer_delim(c(neuropeptide_verified,
                                  neuropeptide_verified_source),
                                delim = ";") %>%
  dplyr::rowwise() %>%
  dplyr::mutate(neuropeptide_verified =
                  trimws(neuropeptide_verified)) %>%
  dplyr::ungroup() %>%
  dplyr::filter(neuropeptide_verified != "",
                 grepl("\\(", neuropeptide_verified_source)) %>%
  dplyr::rowwise() %>%
  dplyr::mutate(neuropeptide_verified_evidence = gsub(
                  "\\(|\\)", "",
                  regmatches(neuropeptide_verified_source,
                             gregexpr("\\((.*?)\\)",
                                      neuropeptide_verified_source))[[1]])) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(neuropeptide_verified_source = gsub("\\(.*?\\)", "", neuropeptide_verified_source),
                neuropeptide_verified_source = gsub(" $", "", neuropeptide_verified_source),
                neuropeptide_verified_source = gsub("et al |et al,", "et al., ", neuropeptide_verified_source),
                neuropeptide_verified_source = gsub("^ ", "", neuropeptide_verified_source),
                neuropeptide_verified_source = gsub("\\)\\)", ")", neuropeptide_verified_source)) %>%
  tidyr::separate_longer_delim(cell_type, delim = ", ") %>%
  dplyr::arrange(cell_type, neuropeptide_verified, neuropeptide_verified_source, neuropeptide_verified_evidence) %>%
  dplyr::distinct(species, region, cell_type, hemilineage,
                   neuropeptide_verified, neuropeptide_verified_source,
                   neuropeptide_verified_evidence) %>%
  dplyr::mutate(neuropeptide_verified_confidence = dplyr::case_when(
    neuropeptide_verified_evidence %in% c("immuno","immuno, intersection") ~ 4,
    neuropeptide_verified_evidence %in% c("transgenics","intersection","MCFO") ~ 3,
    neuropeptide_verified_evidence %in% c("TAPIN","RNAi","EASI-FISH") ~ 2,
    neuropeptide_verified_evidence %in% c("scRNA-seq","RT-PCR", "immuno, unsure", "MCFO, unsure") ~ 1,
    neuropeptide_verified_evidence %in% c("scRNA-seq, unsure") ~ 0,
    TRUE ~ 0
  ))
ft.np <- normalise_gt_fields(ft.np)
if (!is.null(extra)) {
  ft.np <- plyr::rbind.fill(ft.np, extra)
}

# Turn into a matrix.
#
# SPLIT ON A COMMA, NOT ON ", ". The delimiter was the two-character string
# ", ", so a curator who typed "Dh44,Lk" got neither peptide: the pair survived
# the split intact and `spread()` made it a COLUMN, "dh44,lk", that no
# downstream join can ever ask for. 49 of 81 columns were multi-peptide strings
# like this, and the real `lk`/`npf`/`pdf` columns lost those cell types.
# `\\s*` also absorbs "Dh44 , Lk".
ft.np.m <- ft.np %>%
  tidyr::separate_longer_delim(neuropeptide_verified,
                                delim = stringr::regex(",\\s*")) %>%
  dplyr::mutate(neuropeptide_verified = trimws(neuropeptide_verified)) %>%
  dplyr::filter(neuropeptide_verified != "") %>%
  dplyr::distinct(cell_type, neuropeptide_verified, neuropeptide_verified_source, .keep_all = TRUE) %>%
  dplyr::filter(!is.na(cell_type), !is.na(neuropeptide_verified)) %>%
  dplyr::mutate(value = dplyr::case_when(
    grepl("negative",neuropeptide_verified) ~ -1,
    TRUE ~ 1
  )) %>%
  dplyr::mutate(neuropeptide_verified = gsub("-negative.*","",neuropeptide_verified)) %>%
  # Canonicalise BEFORE spreading, so "dNPF" and "NPF" land in one column.
  dplyr::mutate(neuropeptide_verified = canonical_peptide(neuropeptide_verified)) %>%
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
sources_dir <- file.path(repo_root, "gt_sources", "bates_2024")
dir.create(sources_dir, showWarnings = FALSE, recursive = TRUE)
readr::write_csv(x = ft.np,
                 file = file.path(sources_dir,
                   sprintf("%s-gt_np_data.csv",
                           format(Sys.Date(), "%Y%m"))))
############################################################################
### EXCLUSIONS: withdrawn calls, recorded rather than merely deleted     ###
############################################################################
# ASB, 2026-08-31: "To make sure the exclusion set is observed, we might need to have a satellite
# exclusions.csv if we do not have something similar already. New inclusions can go into the same
# extra mechanism."
#
# WHY THIS EXISTS. Inclusions already had a home -- `gt_sources/extra.csv`, merged above. Removals
# did not: a withdrawn call was expressed only as an ABSENCE from gt_np_data.csv. That is fragile
# in the one way that matters here, because this script READS gt_np_data.csv and writes back over
# it: any source that re-supplies a withdrawn row, or any rebuild from an older copy, silently
# resurrects it and nothing anywhere records that a human had removed it on purpose. Seeded from
# M. Zandawala's 2026-08-31 push, which withdrew fifteen cell types.
#
# TWO GRANULARITIES, chosen by whether `neuropeptide` is filled in:
#   blank       -> drop the whole ROW for that cell type.
#   a peptide   -> keep the row and zero THAT ONE column, for withdrawing a single call.
# Blank `region`/`hemilineage`/`species` in an exclusion act as wildcards, so the common case is
# one line naming a cell type.
excl_path <- file.path(repo_root, "gt_sources", "exclusions.csv")
if (file.exists(excl_path)) {
  excl <- readr::read_csv(excl_path, show_col_types = FALSE)
  .norm <- function(x) tolower(trimws(gsub("\u00a0", " ", as.character(x))))
  n_row_before <- nrow(gt.nt.new)
  dropped_total <- 0L; zeroed_total <- 0L; stale <- character(0); already <- character(0)
  for (i in seq_len(nrow(excl))) {
    e <- excl[i, ]
    hit <- rep(TRUE, nrow(gt.nt.new))
    for (f in c("species", "region", "hemilineage", "cell_type")) {
      v <- .norm(e[[f]])
      if (!is.na(v) && nzchar(v)) hit <- hit & (.norm(gt.nt.new[[f]]) %in% v)
    }
    np <- .norm(e[["neuropeptide"]])
    if (!any(hit)) {
      # TWO DIFFERENT THINGS LOOK THE SAME HERE and only one is a problem. If the cell type is
      # absent from the table entirely, the call was already withdrawn upstream and this entry is
      # doing its job pre-emptively -- that is the steady state and must not cry wolf on every
      # build. If the cell type IS present but this entry's region/hemilineage no longer matches
      # it, the exclusion has gone stale against a rename and is silently excluding nothing, which
      # is exactly how a withdrawn call comes back looking verified.
      if (.norm(e[["cell_type"]]) %in% .norm(gt.nt.new$cell_type))
        stale <- c(stale, sprintf("%s (%s)", e[["cell_type"]], e[["region"]]))
      else
        already <- c(already, as.character(e[["cell_type"]]))
      next
    }
    if (is.na(np) || !nzchar(np)) {
      dropped_total <- dropped_total + sum(hit)
      gt.nt.new <- gt.nt.new[!hit, , drop = FALSE]
    } else if (np %in% colnames(gt.nt.new)) {
      zeroed_total <- zeroed_total + sum(hit)
      gt.nt.new[hit, np] <- 0
    } else {
      warning("exclusions.csv row ", i, " names peptide column '", np,
              "', which is not a column of gt_np_data.csv -- NOTHING was excluded for it. ",
              "Fix the spelling; do not leave it, because it reads as an applied exclusion.",
              call. = FALSE)
    }
  }
  message(sprintf("exclusions.csv: %d entries -> %d row(s) dropped, %d call(s) zeroed (%d -> %d rows)",
                  nrow(excl), dropped_total, zeroed_total, n_row_before, nrow(gt.nt.new)))
  # A STALE EXCLUSION IS THE FAILURE MODE THIS FILE INVITES. Once a cell type is renamed upstream,
  # its exclusion silently stops applying and the withdrawn call comes back looking verified. So an
  # entry that matches nothing is reported every build rather than passed over.
  if (length(already))
    message(sprintf("  %d entr(ies) matched nothing because the cell type is absent from the table -- ",
                    length(already)),
            "already withdrawn upstream, so the exclusion held pre-emptively: ",
            paste(utils::head(already, 20), collapse = ", "))
  if (length(stale))
    warning("exclusions.csv: ", length(stale), " entr(ies) name a cell type that IS in the table ",
            "but did not match on region/hemilineage -- the exclusion has gone STALE against a ",
            "rename and is excluding nothing, which is how a withdrawn call comes back looking ",
            "verified. Fix the keys: ", paste(utils::head(stale, 20), collapse = ", "),
            call. = FALSE)
} else {
  message("gt_sources/exclusions.csv absent -- no exclusions applied.")
}

readr::write_csv(x = gt.nt.new,
                 file = file.path(repo_root, "gt_np_data.csv"))

#############################
### Make plot for README  ###
#############################
# Coverage by super_class × peptide. Only counts cells with positive
# (1) evidence; rolls up rare peptides into "other" so the legend
# stays legible.
library(ggplot2)

# Re-pull super_class onto the per-cell-type rows. Use the franken
# table directly — ft is already loaded above.
ft.np.plot <- ft %>%
  dplyr::filter(!is.na(neuropeptide_verified),
                 !neuropeptide_verified %in% c(""," ","NA","unknown")) %>%
  dplyr::distinct(neuron_id, super_class, flow,
                   neuropeptide_verified) %>%
  dplyr::mutate(super_class = ifelse(is.na(super_class),
                                       flow, super_class),
                 super_class = ifelse(is.na(super_class),
                                       "other", super_class)) %>%
  tidyr::separate_longer_delim(neuropeptide_verified, delim = ";") %>%
  tidyr::separate_longer_delim(neuropeptide_verified, delim = ",") %>%
  dplyr::mutate(neuropeptide_verified =
                  trimws(neuropeptide_verified)) %>%
  dplyr::filter(neuropeptide_verified != "",
                 !grepl("negative", neuropeptide_verified))

# Roll low-frequency peptides into "other"
top_peptides <- ft.np.plot %>%
  dplyr::count(neuropeptide_verified, sort = TRUE) %>%
  utils::head(15) %>%
  dplyr::pull(neuropeptide_verified)
ft.np.plot <- ft.np.plot %>%
  dplyr::mutate(peptide = ifelse(neuropeptide_verified %in% top_peptides,
                                   neuropeptide_verified, "other"))

plot_data <- ft.np.plot %>%
  dplyr::count(super_class, peptide) %>%
  dplyr::group_by(super_class) %>%
  dplyr::mutate(percentage = n / sum(n),
                 total_count = sum(n)) %>%
  dplyr::ungroup()

g_np <- ggplot(plot_data,
               aes(x = super_class, y = percentage, fill = peptide)) +
  geom_bar(stat = "identity", position = "fill") +
  geom_text(aes(y = 1.05, label = total_count, group = super_class),
            color = "black", size = 3, fontface = "bold") +
  scale_y_continuous(labels = scales::percent,
                      expand = expansion(mult = c(0, .1))) +
  labs(title = paste("Franken-meta peptide coverage by super class",
                       "(positive evidence only)"),
       x = "super class", y = "percentage",
       fill = "neuropeptide (Symbol)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom") +
  coord_flip()

img_dir <- file.path(repo_root, "inst", "images")
dir.create(img_dir, showWarnings = FALSE, recursive = TRUE)
ggsave(g_np,
        filename = file.path(img_dir, "franken_known_nps.png"),
        width = 9, height = 7)
