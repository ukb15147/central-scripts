## Set up links to institution's central copy of imputed data
for i in $(seq 1 22); do
 ln -s \
  [path_on_hpc]/ukb_imp_chr${i}_v3_MAF0_INFO7.bgen \
  ukb_June2017_imputed_chr${i}_MAF0_INFO7_15147.bgen
 ln -s \
  [path_on_hpc]/ukb_imp_chr${i}_v3_MAF0_INFO7.bgen.bgi \
  ukb_June2017_imputed_chr${i}_MAF0_INFO7_15147.bgen.bgi
done

ln -s ../ukb15147_imp_chr1_v3_s487320.sample ukb15147_imp_chr1_v3_s487320.sample


## Get the full genetic data description
wget  -nd  biobank.ndph.ox.ac.uk/showcase/showcase/docs/ukb_genetic_data_description.txt
