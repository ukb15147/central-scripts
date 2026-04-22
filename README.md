This repository comprises code to support results derived using UK Biobank approved project 15147. Specifically, these are core scripts used to set up genotype, phenotype and covariate data for analysis and pipeline scripts to execute GWAS analysis (separate PLINK and REGENIE pipelines) and HLA association analysis using a supplied phenotype file .

### Data

UK Biobank data cannot be openly shared, but researchers can apply for access.

These scripts make use of genome-wide genotyping array data (field 22418) and genome-wide imputed genotype data (field 22828). Participant QC exclusion lists (which include non-"white British" participants and related individuals) and covariate values (principal components and array type) were derived from the centrally generated QC summary variables (see [resource 531](https://biobank.ndph.ox.ac.uk/showcase/refer.cgi?id=531)) as detailed in the scripts linked below.

### Code

Scripts are organised into subdirectories loosely representing distinct stages of data processing.

##### 1. Genotype array data

Code to process the provided array data to remove participants failing QC, and to create covariate files for use in GWAS.

| Script                                                                                | Description                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [1_s01_get_data.sh](1_array_data/1_s01_get_data.sh)                                   | Download the project-specific .fam file using the UKB helper programme _ukbgene_ (now deprecated, see [resource 664](https://biobank.ndph.ox.ac.uk/ukb/refer.cgi?id=664))                                                                                                                                                                                                                                                                         |
| [2_s01_compile_genotype_data.sh](1_array_data/2_s01_compile_genotype_data.sh)         | Set up links to institution's central copy of array genotype data and to project-specific .fam file. Add links to the sample QC file (ukb_sqc_v2.txt) and variant QC file (ukb_snp_qc.txt) provided by UKB (see [resource 531](https://biobank.ndph.ox.ac.uk/ukb/refer.cgi?id=531))                                                                                                                                                               |
| [3_s02_process_sample_exclusions.sh](1_array_data/3_s02_process_sample_exclusions.sh) | Assemble an exclusion list from UKB central QC metrics, including: non-white-British, gender mismatch, excess relatives, call rate <0.95, excess heterozygosity/missingness, not used in PCA (this should ensure close relatives are removed). Additionally, exclude participants with call rate <98% in a set of "good" variants (defined as variants with <90% missingness across the samples remaining after the previous round of exclusions) |
| [4_get_basic_covars.sh](1_array_data/4_get_basic_covars.sh)                           | Pull out variables from the sample QC file into PLINK format covariate files                                                                                                                                                                                                                                                                                                                                                                      |

##### 2. Genome-wide imputed data

Code to make a project-specific PLINK2 fileset of imputed genotype calls for white British, unrelated, post-QC participants. The starting point for these scripts is a copy of the UKB imputed genetic data in .bgen format that is centrally held for our institution and has already had variants with imputation INFO score <0.7 filtered out (using software such as _qctool_).

| Script                                                                                      | Description                                                                                                                                                                  |
| ------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [1_s01_get_data.sh](2_imputed_data/1_s01_get_data.sh)                                       | Download the project-specific .sample file using the UKB helper programme _ukbgene_ (now deprecated, see [resource 664](https://biobank.ndph.ox.ac.uk/ukb/refer.cgi?id=664)) |
| [2_s01_compile_imputed_data.sh](2_imputed_data/2_s01_compile_imputed_data.sh)               | Set up links to institution's central copy of imputed genotypes and to project-specific .sample file                                                                         |
| [3_s04_filter_convert_imputed_data.sh](2_imputed_data/3_s04_filter_convert_imputed_data.sh) | Convert bgen to PLINK2 format (pgen/pvar/psam), keeping only white British, unrelated participants passing QC and variants with MAF>0.5%                                     |

##### 3. GWAS analysis pipeline (PLINK)

Code to perform logistic regression based GWAS in PLINK, using the imputed dataset above. Plus basic downstream analysis.

| Script                                                                                                       | Description                                                                                                                                                                                                                                                                                                                                      |
| ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [script1_ukb_GWAS_CREATE.sh](3_assoc_genome_wide/script1_ukb_GWAS_CREATE.sh.sh)                              | Run logistic regression GWAS in PLINK2 via `--glm`, using the basic covariates generated above. Phenotype file and up-to-date withdrawal list are passed as script arguments. Extract significant association loci using PLINK1.9's `--clump` method, with lead p-values below 1.0×10<sup>-5</sup>. HPC script that runs one job per chromosome. |
| [script1_ukb_GWAS_customCOVs.CREATE.sh](3_assoc_genome_wide/script1_ukb_GWAS_customCOVs.CREATE.sh)           | Alternative script1 that allows an alternative covariate file to be passed as an additional argument.                                                                                                                                                                                                                                            |
| [script2_post_ukb_GWAS_processing_CREATE.sh](3_assoc_genome_wide/script2_post_ukb_GWAS_processing_CREATE.sh) | Post-process the GWAS results: merge per-chromosome `logistic.hybrid` files into a single file; calculate LDSC intercept; calculate lambda; generate Manhattan and QQ plots                                                                                                                                                                      |
 
##### 4. GWAS analysis pipeline (REGENIE)

Code to perform GWAS in REGENIE, using the imputed dataset above. Plus basic downstream analysis.

| Script                                                                             | Description                                                                                                                                                                              |
| ---------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [regenie1_preliminary.sh](4_assoc_regenie/regenie1_preliminary.sh)                 | Pre-process the QCed array data (generated in section 1 above) to be REGENIE-compatible                                                                                                  |
| [regenie2_predictors.sh](4_assoc_regenie/regenie2_predictors.sh)                   | Run REGENIE step 1 (fitting null model) on pre-processed array data. Phenotype and covariate files supplied as script arguments (assumes binary trait).                                  |
| [regenie3_gwas.sh](4_assoc_regenie/regenie3_gwas.sh)                               | Run REGENIE step 2 (association testing) on whole-genome imputed data (generated in section 2 above). Phenotype and covariate files supplied as script arguments (assumes binary trait). |
| [regenie4_postprocessing.bash.sh](4_assoc_regenie/regenie4_postprocessing.bash.sh) | Process REGENIE output to merge per-chromosome files into a single file, add standard-format p-value and filter based on MAF and INFO.                                                   |
| [regenie5_plots.sh](4_assoc_regenie/regenie5_plots.sh)                             | Calculate lambda and generate Manhattan and QC plots                                                                                                                                     |

##### 5. HLA association analysis pipeline (PLINK)

Code to prepare imputed HLA data for PLINK and perform association testing.

| Script                                                             | Description                                                                                                                                                                 |
| ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [1_s03_transpose_dosage.sh](5_assoc_HLA/1_s03_transpose_dosage.sh) | Transpose the imputed HLA dosages file supplied by UKB into a `.dosage` format readable by PLINK                                                                            |
| [2_hla1_assoctest.sh](5_assoc_HLA/2_hla1_assoctest.sh)             | Run association testing in PLINK2 via `--dosage`, using the basic covariates generated above. Phenotype file and up-to-date withdrawal list are passed as script arguments. |
