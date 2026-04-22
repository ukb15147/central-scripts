#!/bin/bash -l
#SBATCH --job-name=ukb_regenie_plot
#SBATCH --partition cpu
#SBATCH --mem=8gb
#SBATCH --ntasks=2
#SBATCH --nodes=1
#SBATCH --output=/scratch/prj/derm_ukb/assoc_genome_wide/sbatch_logs/%u_%x_%j
#SBATCH --time=2-0


cd /scratch/prj/derm_ukb/assoc_genome_wide/regenie_output

STEM=$1    ## The same output filestem used in previous steps
TITLE=$2   ## Title for Manhattan and QQ plots. Enclose in single quotes if spaces

cat ukb_MAF01_INFO7_${STEM}_chrALL.regenie |\
 awk 'F==1{a[$1]=$1}F==2{if($3 in a){print $3,$15}}' \
 F=1 /scratch/prj/derm_ukb/repository/independent_vars/indep_vars_1500_150_0.2_maf0.01.prune.in \
 F=2 - > ${STEM}_indep_SNP_Pvals

NUMS=`grep "cases and" ukb_MAF0_INFO7_${STEM}_chr22.log | awk '{print $3,$6}'`


module load r/4.2.2-gcc-10.3.0-withx-rmath-standalone-python3+-chk-version
export R_LIBS="/scratch/prj/derm_ukb/software/R/x86_64-pc-linux-gnu-library/4.2"

Rscript /scratch/prj/derm_ukb/repository/utility_scripts/lambda_gc.R \
 ${STEM}_indep_SNP_Pvals FALSE 2 ${NUMS}

rm ${STEM}_indep_SNP_Pvals

Rscript /scratch/prj/derm_ukb/repository/utility_scripts/generate_manhattan_plot_v1.R \
 ukb_MAF01_INFO7_${STEM}_chrALL.regenie \
 1 2 15 \
 NONE \
 "${TITLE}" \
 ${STEM}_manhattan.png \
 1

Rscript /scratch/prj/derm_ukb/repository/utility_scripts/generate_qqplot_v1.R \
 ukb_MAF01_INFO7_${STEM}_chrALL.regenie 15 "${TITLE}" ${STEM}_qq.png
