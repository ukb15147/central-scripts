#!/bin/bash -l
#SBATCH --output=/scratch/users/%u/000_sbatch_job_output/%A_%a.out
#SBATCH --time=5-0
#SBATCH --mem=128gb
#SBATCH --constraint="haswell"
#SBATCH --array=1-22

plink(){
 [path_on_hpc]/software/plink2 "$@"
}

CHR=$SLURM_ARRAY_TASK_ID
GROUPDIR="[path_on_hpc]/derm_ukb/"

## Note PLINK applies keep first and then remove, i.e. withdrawals will be removed
## even if include in the ukb4 fam

plink \
--bgen ukb_June2017_imputed_chr${CHR}_MAF0_INFO7_15147.bgen ref-first \
--sample ukb15147_imp_chr1_v3_s487320.sample \
--remove ${GROUPDIR}/withdrawals/withdrawals_20200204.exclude \
--keep ${GROUPDIR}/ukb_genotype_data/ukb_step4_interim.fam \
--maf 0.005 \
--make-pgen \
--out ukb_imputed_15147_MAF0_005_INFO7_chr${CHR}

