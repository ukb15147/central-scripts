## Prints sample IDs, array type as 0/1 and first 20 PCs to a PLINK format covariates file

cut -d' ' -f1,2,9,32-51 samples_with_qc.txt |\
 sed 's/UKBB/0/g' | sed 's/UKBL/1/g' > samples_20PCs_array.covar


## Prints sample IDs, array type as 0/1, sex and first 20 PCs to a PLINK format covariates file

cut -d' ' -f1,2,9,17,32-51 samples_with_qc.txt |\
 sed 's/UKBB/0/g' | sed 's/UKBL/1/g' |\
 sed "s/M/1/g" | sed "s/F/2/g" > samples_20PCs_array_sex.covar
