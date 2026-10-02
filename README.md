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

## How to Contribute Data

### For Git Novices

1. Download the `gt_np_data.csv` file and open it with your preferred spreadsheet application.
2. Add your data to the bottom of the file and save it as a CSV.
3. On the repository page, click the "+" sign next to "Code" and select "Upload Files".
4. Upload your modified `gt_np_data.csv` file, ensuring the filename remains unchanged.
5. Fill in the commit form:
   - Provide a concise description of your changes in the first field.
   - Add more detailed information in the "Add an optional extended description..." field.
6. Select "Create a new branch for this commit and start a pull request".
7. Review your changes on the "Open a pull request" page and click "Create pull request".
8. Wait for review from a maintainer. Be prepared to answer follow-up questions about your data.

### For Git Users

1. Clone this repository and create a new branch.
2. Modify the `gt_np_data.csv` file.
3. Commit your changes with a meaningful commit message and push to your branch.
4. Create a Pull Request for your branch when you're satisfied with your changes.

### Adding and withdrawing calls: `gt_sources/extra.csv` and `gt_sources/exclusions.csv`

Two satellite files sit beside the main table and are applied by `R/organise_np_data.R` on every
rebuild. Use them in preference to hand-editing `gt_np_data.csv`, because that script reads the
table and writes back over it: a hand edit survives only until a source re-supplies the row.

- **`gt_sources/extra.csv` — inclusions.** Calls to add that no upstream source carries yet.
  **One row per (cell type, SOURCE)**, not per peptide: `neuropeptide_verified_source` holds a
  single value, so several peptides from one study go on one row comma-separated, while one call
  attested by two studies is two rows. The builder APPENDS these, so a cell type can end up with
  several rows and that is correct — `FB1B` carries an Nplp1 call from Wolff et al. 2024 and
  another from Janelia.
- **`gt_sources/exclusions.csv` — withdrawals.** Calls to remove. Leave `neuropeptide` blank to
  drop the whole row for that cell type, or name a peptide to zero that single call and keep the
  row.

**Key an exclusion on the cell type, and leave `region` and `hemilineage` blank.** They are
wildcards, and blank is almost always right: region and hemilineage are exactly the fields
curation *changes*. In the 2026-08-31 update ten fan-shaped-body types moved from
`midbrain`/`0` to `central_brain`/`LALv1_dorsal`, and an exclusion keyed on the old region would
have silently stopped applying while still looking present in the file.

**What an exclusion CANNOT do: withdraw one source's row when two sources supply the same cell
type.** It is keyed on the cell type, and `extra.csv` appends, so both rows share the key —
dropping the row kills both calls, and naming the peptide zeroes both. There is no way at present
to say *"drop the Janelia duplicate, keep the Wolff one"*. If you need that, say so rather than
deleting rows by hand: it wants an optional `source` column on `exclusions.csv`, which is a schema
change. (Raised 2026-10-02, when exactly this was asked for across eight fan-shaped-body and
vDelta types.)

The builder reports what it did every run: rows dropped, calls zeroed, and two distinct
no-match cases kept apart — an entry whose cell type is *absent* from the table is holding
pre-emptively and is reported as a message, whereas an entry whose cell type is *present* but
whose keys no longer match has gone **stale** against a rename and raises a warning, because that
is how a withdrawn call comes back looking verified.

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
