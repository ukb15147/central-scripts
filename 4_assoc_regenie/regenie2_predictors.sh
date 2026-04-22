#!/bin/bash -l
#SBATCH --job-name=ukb_regenie_predictors
#SBATCH --partition cpu,simpson_cpu
#SBATCH --mem=96gb
#SBATCH --ntasks=16
#SBATCH --nodes=1
#SBATCH --output=/scratch/prj/derm_ukb/assoc_genome_wide/sbatch_logs/%u_%x_%j
#SBATCH --time=2-0

## Important note: the running time is very sensitive to the combination of CPUs (ntasks),
## threads, block size and possibly memory. Running time is at least several hours so using
## the wrong combination can mean the job times out. The current parameters have worked for
## a GWAS of 190k participants. Other combinations of parameters were tested; log files with
## times are in the directory regenie_performance_CREATE/


cd /scratch/prj/derm_ukb/assoc_genome_wide

PHENO=$1     ## Phenotype file. Header row (FID IID pheno_name) with case=1, ctrl=0 in col 3.
             ## Ensure non-British or non-Europeans excluded here if not wanted in analysis
COVAR=$2     ## Space separated covariates file with header row. First two columns FID IID
WITHDR=$3    ## Latest withdrawals file (double column). As of 10/2023: /scratch/prj/derm_ukb/withdrawals/withdrawals_20230915_fullukb.exclude
OUT_STEM=$4  ## A descriptive filename stem (without spaces)

echo "Pheno: $PHENO"
echo "Covariates: $COVAR"
echo "Withdrawals: $WITHDR"
echo "Output: ${OUT_STEM}"

#module load regenie/3.2.4-gcc-10.3.0
module load regenie/3.2.4-gcc-13.2.0

regenie () {
  regenie_v3.2.4.gz_x86_64_Linux "$@"
}

regenie \
--step 1 \
--bed regenie_output/ukb_ALLSAMPLES_chr1_23_QC \
--covarFile $COVAR \
--phenoFile $PHENO \
--remove $WITHDR \
--bsize 1000 \
--bt --lowmem \
--lowmem-prefix regenie_output/tmp_rg_${OUT_STEM} \
--threads 16 \
--out regenie_output/fit_bin_out_${OUT_STEM}
