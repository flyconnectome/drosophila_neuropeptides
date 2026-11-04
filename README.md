# Drosophila neuropeptides

This repository contains curated data on neuropeptides found in *Drosophila melanogaster*. The data is stored in a version-controlled CSV file named `gt_np_data.csv`, with changes managed through GitHub Pull Requests.

For a complete list of references for our ground truth, please see our [CITATIONS.md](CITATIONS.md) file.

## Scope

This repository focuses on neuropeptides in Drosophila, which are larger signaling molecules than fast-acting neurotransmitters. Neuropeptides often act as neuromodulators, affecting the properties of neural circuits. For fast-acting small molecule neurotransmitter annotation, please refer to our separate repository: [funkelab/drosophila_neurotransmitters](https://github.com/funkelab/drosophila_neurotransmitters).

The repository includes information on ~50 known Drosophila neuropeptides, including:

1. **Adipokinetic hormone (Akh):** Released from the corpora cardiaca, involved in mobilizing energy stores.
2. **Allatostatin A (AstA):** Inhibits juvenile hormone synthesis and regulates feeding behavior.
3. **Allatostatin C (AstC):** Involved in feeding regulation and sleep.
4. **Allatostatin CC (AstCC):** Related to AstC, functions not fully characterized.
5. **Bursicon (Burs):** Involved in cuticle tanning and wing expansion after eclosion.
6. **Capability (Capa):** Also known as Periviscerokinin, involved in fluid homeostasis.
7. **CCHamide-1 (CCHa1):** Regulates feeding behavior and gut function.
8. **CCHamide-2 (CCHa2):** Involved in feeding regulation and gustatory sensitivity.
9. **CNMamide (CNMa):** Functions in male courtship behavior.
10. **Corazonin (Crz):** Regulates stress responses, metabolism, and pigmentation.
11. **Crustacean cardioactive peptide (CCAP):** Involved in ecdysis and heart rate regulation.
12. **Diuretic hormone 31 (Dh31):** Regulates fluid secretion and circadian rhythms.
13. **Diuretic hormone 44 (Dh44):** Involved in water and ion homeostasis.
14. **Drosulfakinin (Dsk):** Regulates feeding and satiety.
15. **Ecdysis triggering hormone (ETH):** Critical for ecdysis behavior.
16. **Eclosion hormone (Eh):** Involved in ecdysis and eclosion behaviors.
17. **FMRFamide (FMRFa):** Modulates synaptic transmission and muscle contraction.
18. **Glycoprotein hormone alpha 2 (Gpa2):** Forms heterodimers with Gpb5.
19. **Glycoprotein hormone beta 5 (Gpb5):** Forms heterodimers with Gpa2.
20. **Hugin (Hug):** Regulates feeding behavior and locomotion.
21. **Insulin-like peptides (Ilp1-8):** Involved in growth, metabolism, and lifespan regulation.
22. **Ion transport peptide (ITP):** Regulates ion and fluid homeostasis.
23. **Leucokinin (Lk):** Involved in feeding, sleep, and fluid homeostasis.
24. **Myoinhibiting peptide (Mip):** Also known as Allatostatin B, regulates ecdysis and sleep.
25. **Myosuppressin (Ms):** Modulates heart rate and muscle contractions.
26. **Natalisin:** Involved in reproductive behaviors.
27. **Neuropeptide F (NPF):** Regulates feeding behavior, alcohol sensitivity, and social behavior.
28. **Neuropeptide-like precursor 1-4 (Nplp1-4):** Functions not fully characterized.
29. **Orcokinin:** Involved in circadian behaviors and stress responses.
30. **Partner of Bursicon (Pburs):** Forms heterodimers with Bursicon.
31. **Pigment-dispersing factor (Pdf):** Critical for circadian rhythm regulation.
32. **Proctolin (Proc):** Enhances muscle contractions.
33. **Prothoracicotropic hormone (Ptth):** Regulates molting and metamorphosis.
34. **RYamide (RYa):** Involved in feeding behavior regulation.
35. **Sex Peptide (SP):** Transferred during mating, affects female post-mating behaviors.
36. **Short neuropeptide F (sNPF):** Involved in feeding behavior and sleep regulation.
37. **SIFamide (SIFa):** Modulates sexual behavior and sleep.
38. **Tachykinin (Tk):** Modulates olfactory processing and aggressive behaviors.
39. **Trissin:** Functions not fully characterized.

## Our Goal

Our goal is to collate as much data from the literature as possible, linking neuropeptide information to neuronal cell types from connectomic datasets. 
Current datasets include:

- FAFB-FlyWire (whole brain)
- HemiBrain (partial midbrain)
- FANC (ventral nerve cord)
- MANC (ventral nerve cord)
- optic-lobe (optic lobe)
- maleCNS (whole nervous system)
- BANC (whole nervous system)
- L1 (whole larval nervous system)

Cross data set cell type mapping is given in the file: `/inst/extdata/cell_type_cross_matching.csv`

[Yervand Azatian](https://www.linkedin.com/in/yervand-azatian/) with Alexander Bates, Wei Lee and Jan Funke has predicted dense core vesicles across FAFB, the results are in good agreement with 
the ground truth this repository is collating:

![dcv_predictions_known_nps](https://github.com/funkelab/drosophila_neuropeptides/blob/main/inst/images/dcv_predictions_known_nps.png?raw=true)

Coverage of `neuropeptide_verified` annotations across `franken_meta` super-classes (positive evidence only):

![franken_known_nps](https://github.com/funkelab/drosophila_neuropeptides/blob/main/inst/images/franken_known_nps.png?raw=true)

## How to add or withdraw ground truth

**Never edit `gt_np_data.csv` by hand.** `R/organise_np_data.R` regenerates that table, so a hand edit
is lost at the next rebuild. Every change goes through one of two small files in `gt_sources/`:

| To... | Edit | |
|---|---|---|
| add a call | `gt_sources/extra.csv` | one row per cell type + source |
| withdraw a call | `gt_sources/exclusions.csv` | one row per cell type |

### Adding a call, step by step

**1. Find the cell type name.** Use the FAFB-FlyWire name for the brain and the MANC name for the
nerve cord. If the paper gives FlyWire root IDs, map them to cell types; root IDs change between
FlyWire versions, so check that they match v783. Types are the unit here: a paper that sampled one
hemisphere or some of a type's neurons still gives a call for the type.

**2. Add one row to the bottom of `gt_sources/extra.csv`.** The columns, in order:

```
species,region,hemilineage,cell_type,neuropeptide_verified_evidence,neuropeptide_verified,neuropeptide_verified_source,neuropeptide_verified_confidence
```

For example:

```
adult_drosophila_melanogaster,central_brain,,LNd_b,immuno,Tristin,"Brown et al., 2024",3
```

| Column | What to write |
|---|---|
| `species` | `adult_drosophila_melanogaster` |
| `region` | `central_brain`, `ventral_nerve_cord` or `optic_lobe` |
| `hemilineage` | leave blank, unless the type sits in exactly one |
| `cell_type` | the name from step 1 |
| `neuropeptide_verified_evidence` | the method, from the list below |
| `neuropeptide_verified` | gene symbols as in Zandawala 2024 (`npf`, `asta`, `proc`). Several peptides from one study go in one quoted field: `"sNPF, Dh31"` |
| `neuropeptide_verified_source` | one study, as `"Author et al., YEAR"`, in quotes because of the comma. If two studies attest a call, write two rows |
| `neuropeptide_verified_confidence` | an integer from 0 to 5; see [About the Data](#about-the-data). It is used exactly as you write it, so always fill it in |

**Evidence terms.** Use one of these, spelled exactly, because the DCV analysis reads the spelling to
decide whether a call is protein-level or gene-level:

| Evidence term | Level | Usual confidence |
|---|---|---|
| `immuno`, `immuno, intersection` | protein | 4 or 5 |
| `transgenics`, `intersection`, `MCFO` | gene | 3 |
| `EASI-FISH`, `TAPIN-seq`, `RNAi` | gene | 2 to 3 |
| `HCR-FISH` | gene | 3 |
| `scRNA-seq`, `RT-PCR` | gene | 1 to 3 |

A new term needs checking first: `HCR` on its own, for example, matched neither level, so its calls
silently counted for nothing. Ask before inventing one.

**A cell type that lacks a peptide.** To record that a type does not express neuropeptides, write
`neuropeptides-negative` in `neuropeptide_verified`, with the evidence and source as usual. The table
then holds `-1` for it.

**3. Cite the source, if it is new.** Add it in all three places, using the same source string as your
row:
- `CITATIONS.md`: append, do not renumber.
- `gt_sources/citations.csv`: `citation,pmid,doi`; write `preprint` for the pmid where there is none.
- `gt_sources/citations.bib`: BibTeX.

**4. Send it in.**
- *Not comfortable with Git:* open `gt_sources/extra.csv` on GitHub, click the pencil icon, add your
  rows at the bottom, and choose "Create a new branch for this commit and start a pull request".
  A maintainer rebuilds the table and merges. Say in the pull request where the call comes from.
- *Using Git:* run `git pull`, add your rows, then rebuild (step 5) and push.
  Other people also append to `extra.csv`. If it conflicts, keep both blocks, take `gt_np_data.csv`
  from origin and rebuild; never merge the generated table by hand.

**5. Rebuild.** From the repository root:

```bash
Rscript R/organise_np_data.R
```

This reads `bancr::franken_meta()` from SeaTable (it needs `BANCTABLE_TOKEN`; there is a GCS fallback),
applies both files and rewrites `gt_np_data.csv`. Read its report, then check that your row is in
`gt_np_data.csv` and commit all the changed files together.

**6. Tell whoever uses it.** The table does not reach an analysis by itself. In the DCV project
(`htem/dcv`), run `Rscript R/process/build_np_labels.R` to rebuild the peptide maps, then refit the
DCV-rich threshold (`R/process/compute_threshold.R`), because the protein-level calls are its positive
set. So a new protein-level call can move the threshold, and with it every DCV-rich call in the paper.
Before adding one, check that type's soma DCV density. If the evidence is sound but the type would
damage the calibration, keep its row in `extra.csv` and also add the type to `exclusions.csv`: the
first records what the study found, the second what we calibrate on.

### Withdrawing a call

Add a row to `gt_sources/exclusions.csv`. Its columns:

```
species,region,hemilineage,cell_type,neuropeptide,withdrawn_calls,withdrawn_from_region,reason,source,date_added,match_source
```

- **Key it on the cell type, and leave `region` and `hemilineage` blank.** They are wildcards, and they
  are the fields curation changes: an exclusion keyed on an old region silently stops applying while
  still looking present in the file.
- **Leave `neuropeptide` blank** to drop the whole row, or name one peptide to zero that single call.
- **Fill in `match_source`** to drop only one study's row where two studies supply the same cell type,
  for example to remove a Janelia duplicate and keep the Wolff et al. row. Blank means every source.
- Always fill in `reason`, `source` and `date_added`.

### What the builder reports

Each rebuild prints the rows dropped and the calls zeroed, and keeps two no-match cases apart. An entry
whose cell type is *absent* from the table is holding pre-emptively, and is reported as a message. An
entry whose cell type is *present* but whose keys no longer match has gone **stale** against a rename,
and raises a warning, because that is how a withdrawn call comes back looking verified.

## About the Data

Our goal is to collate comprehensive data on Drosophila neuropeptides, including information on their expression patterns, receptors, and known functions. 

The file `gt_np_data.csv` contains one row per cell type + study, where the given study has identified a neuropeptide (or multiple neuropeptides) used by the given cell type. 

It uses a single cell type name, that can be linked between connectomes using the file `exdata/cell_type_cross_matching.csv`.

The data columns are:

*species* - the species name for the observation, for now this is only d. melanogaster

*region* - the gross subregion for the cell type, i.e. midbrain, optic lobes, ventral nerve cord

*hemilineage* - the hemilineage bundle to which the cell type belongs, in the nomenclature of Ito et al., 2013 and (midbrain), or (ventral nerve cord)

*cell_type* - a cell type name relevant to one of the connectomic datasets. In general, we prefer a FAFB-FlyWire (brain) or MANC (ventral nerve cord) name.

*neuropeptide_verified_source* - the name of the study from which the observation this row records has originated. Rows are unique combinations of `cell_type` and `neuropeptide_verified_source`, so each can repeat over multiple rows when many studies look at the same cell type, or when one study reports on many cell types.

*neuropeptide_verified_evidence* - the method used by the given study to determine peptide expression (e.g. `immuno`, `EASI-FISH`, `RNAi`, `transgenics`, `MCFO`, `scRNA-seq`).

*neuropeptide_verified_confidence* - an integer expressing how confident the curator is that the study correctly identified the peptide for the given cell type, and how well that cell type has been matched to connectome data:
  - 5: evidence for protein expression in the given cell type, cell-type-specific labelling.
  - 4: evidence for protein expression with coarser anatomical detail / reliable transcript expression using in-situ hybridisation, and ideally for which some negative data is available (different neuropeptide options tried per cell type).
  - 3: identification of RNA transcripts related to neuropeptide expression.
  - 2: unreliable morphological match to the EM / bulk RNA sequencing / gross neuroanatomy based on immunohistochemistry.
  - 1: genetic knockdown (e.g. RNAi) of neuropeptide pathways / speculative morphological matches to EM.
  - 0: educated guesses at expression based on any of the above, but lacking anatomical precision in matching to the EM.

*peptide columns* (`asta`, `astc`, `dh31`, `dh44`, `dsk`, `eh`, `eth`, `fmrfa`, `hug`, `ilp2`, `ilp3`, `ilp5`, `itp`, `lk`, `mip`, `ms`, `npf`, `nplp1`, `pdf`, `proc`, `sifa`, `snpf`, `tk`, `trissin`, `spab`, `amn`, …) — one column per peptide, named with the lowercase Zandawala 2024 gene symbol (see [`gt_sources/zandawala_2024/neuropeptide_meta.csv`](gt_sources/zandawala_2024/neuropeptide_meta.csv) for the canonical list of Symbols, full names, and aliases). Values are `-1` (negative evidence), `0` (no evidence either way), or `1` (positive evidence). Negative data is rare but valuable — please contribute it if you have it.

> **Schema note (May 2026)**: peptide annotations were previously stored mixed into the `neurotransmitter_verified` column of `franken_meta` (alongside small-molecule transmitters). They have been migrated into the dedicated `neuropeptide_verified` column, with corresponding evidence in `neuropeptide_verified_source`, and peptide names normalised to Zandawala 2024 gene symbols (e.g. `allatostatin-a` → `AstA`, `tachykinin` → `Tk`). The script `R/organise_np_data.R` now reads from `neuropeptide_verified` directly. Old column headers in `gt_np_data.csv` like `allatostatin-a`, `dnpf`, `proctolin`, `eclosion_hormone`, `tachykinin`, `space_blanket` are replaced by `asta`, `npf`, `proc`, `eh`, `tk`, `spab` respectively.

## About the Meta Data

The `zandawala_2024/neuropeptide_meta.csv` file contains detailed meta information for each neuropeptide:

- `Symbol`: Short identifier for the neuropeptide
- `Name`: Full name of the neuropeptide
- `Other names`: Alternative names or synonyms
- `Annotation ID`: Gene ID in FlyBase
- `Cytology`: Chromosomal location
- `Scaffold`: Genomic scaffold location
- `Mature peptide sequence`: Amino acid sequence of the mature peptide (if known)
- `Receptors`: Known receptors for the neuropeptide
- `Vertebrate ortholog`: Closest vertebrate equivalent
- `Family`: Neuropeptide family
- `Expressed in brain`: Whether the neuropeptide is expressed in the brain
- `Coexpressed with other peptide`: Whether it's coexpressed with other neuropeptides
- `Notes`: Additional relevant information

## Acknowledgements

*As of July 20th 2024 -- repo private* 

This data was collated by [Alexander Bates](https://as-bates.netlify.app/portfolio/) at Harvard Medical School while in the group of Prof. Rachel Wilson
[Meet Zandawala](https://www.unr.edu/neuroscience/people/meet-zandawala) at the University of Nevada, Reno. 
It is manageed and curated together with [Diane Adjavon](https://adjavon.github.io/) in the laboratory of [Jan Funke](https://www.hhmi.org/scientists/jan-funke) at Janelia Research Campus. 

If you use this collected data in your research please liaise with Alex, Diane, Meet and Jan on the appropriate ways to acknowledge this resource.

## Citations

1. Bates, A. S., Janssens, J., Jefferis, G. S., & Aerts, S. (2019). Neuronal cell types in the fly: single-cell anatomy meets single-cell genomics. Current Opinion in Neurobiology, 56, 125-134.

2. Eckstein, N., Bates, A. S., Champion, A., Du, M., Yin, Y., Schlegel, P., ... & Funke, J. (2024). Neurotransmitter classification from electron microscopy images at synaptic sites in Drosophila melanogaster. Cell, 187(10), 2574-2594.

For a complete list of references, please see our [CITATIONS.md](CITATIONS.md) file.

## Contact

For questions or concerns, please open an issue in this repository or contact Alexander Bates (alexander_bates[at]hms.harvard.edu) 
and Meet Zandawala (meet.zandawala[at]uni-wuerzburg.de).
