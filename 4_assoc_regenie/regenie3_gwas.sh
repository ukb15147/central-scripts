#!/bin/bash -l
#SBATCH --job-name=ukb_regenie_gwas
#SBATCH --partition cpu,simpson_cpu
#SBATCH --mem=6gb
#SBATCH --ntasks=4
#SBATCH --nodes=1
#SBATCH --output=/scratch/prj/derm_ukb/assoc_genome_wide/sbatch_logs/%u_%x_%j
#SBATCH --array=1-22
#SBATCH --time=2-0

#module load regenie/3.2.4-gcc-10.3.0
module load regenie/3.2.4-gcc-13.2.0
regenie () {
  regenie_v3.2.4.gz_x86_64_Linux "$@"
}
plink () {
 /scratch/prj/derm_ukb/software/plink "$@"
}

cd /scratch/prj/derm_ukb/assoc_genome_wide

PHENO=$1     ## Same as script regenie2_predictors.sh
COVAR=$2     ## Same as script regenie2_predictors.sh
WITHDR=$3    ## Same as script regenie2_predictors.sh
OUT_STEM=$4  ## Same as script regenie2_predictors.sh

CHR=$SLURM_ARRAY_TASK_ID

regenie \
--step 2 \
--bgen /scratch/prj/derm_ukb/ukb_imputed_geno_data/ukb_June2017_imputed_chr${CHR}_MAF0_INFO7_15147.bgen \
--ref-first \
--sample /scratch/prj/derm_ukb/ukb_imputed_geno_data/ukb15147_imp_chr1_v3_s487320.sample \
--phenoFile $PHENO \
--covarFile $COVAR \
--remove $WITHDR \
--bt \
--firth --approx --pThresh 0.01 \
--pred regenie_output/fit_bin_out_${OUT_STEM}_pred.list \
--bsize 400 \
--out regenie_output/ukb_MAF0_INFO7_${OUT_STEM}_chr${CHR}



