## Set up PLINK binary fileset
ln -s [path_on_hpc]/ukb15147_cal_chr1_v2_s488288.fam ukb_June2017_fullgeno_15147.fam
ln -s [path_on_hpc]/ukb_binary_v2.bim ukb_June2017_fullgeno_15147.bim
ln -s [path_on_hpc]/ukb_binary_v2.bed ukb_June2017_fullgeno_15147.bed

## Link to supporting files
ln -s [path_on_hpc]/ukb_sqc_v2.txt link_to_ukb_sqc_v2.txt
ln -s [path_on_hpc]/ukb_sqc_v2_fields.txt link_to_ukb_sqc_v2_fields.txt
ln -s [path_on_hpc]/ukb_snp_qc.txt link_to_ukb_snp_qc.txt

## Get the full genetic data description
wget  -nd  biobank.ndph.ox.ac.uk/showcase/showcase/docs/ukb_genetic_data_description.txt
