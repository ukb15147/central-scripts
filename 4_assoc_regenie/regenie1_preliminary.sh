#!/bin/bash -l
#SBATCH --job-name=ukb_regenie_preliminary
#SBATCH --partition brc,shared
#SBATCH --mem=6gb
#SBATCH --ntasks=4
#SBATCH --nodes=1
#SBATCH --output=/scratch/groups/derm_ukb/assoc_genome_wide/sbatch_logs/%u_%x_%j
#SBATCH --constraint="haswell"
#SBATCH --time=2-0


module load utilities/use.dev
module load apps/regenie/2.2.4-mkl
module load apps/plink/1.9.0b6.10

### JS - 24/05/22: I've already run this and it doesn't need to be run again
### but if anyone wants to change QC settings
### you can re-run this (and change the output path!)

cd /scratch/groups/derm_ukb/assoc_genome_wide

# regenie throws an error on chr codes above 23

awk '$1<24' /scratch/groups/derm_ukb/ukb_genotype_data/ukb_step4_interim.bim | awk '{print $2}' > regenie_output/QCd_snps_chr1_23.txt


### perform QC on original genotyped data - as recommended by regenie doc
plink \
--bfile /scratch/groups/derm_ukb/ukb_genotype_data/ukb_June2017_fullgeno_15147 \
--extract regenie_output/QCd_snps_chr1_23.txt \
--maf 0.01 --mac 100 --geno 0.1 --hwe 1e-15 \
--make-bed --out regenie_output/ukb_step4_interim_chr1_23_QC

### Additional options? Not needed
#  --mind 0.1 \


## ND - add symlink with new name to clarify that all samples are included
cd regenie_output
ln -s ukb_step4_interim_chr1_23_QC.bed ukb_ALLSAMPLES_chr1_23_QC.bed
ln -s ukb_step4_interim_chr1_23_QC.fam ukb_ALLSAMPLES_chr1_23_QC.fam
ln -s ukb_step4_interim_chr1_23_QC.bim ukb_ALLSAMPLES_chr1_23_QC.bim
