#!/bin/bash -l
#SBATCH --job-name=ukb_regenie_post
#SBATCH --partition cpu
#SBATCH --mem=4gb
#SBATCH --output=/scratch/prj/derm_ukb/assoc_genome_wide/sbatch_logs/%u_%x_%j
#SBATCH --time=2-0


cd /scratch/prj/derm_ukb/assoc_genome_wide

OUT_STEM=$1
echo "Output: ${OUT_STEM}"


head -1 regenie_output/ukb_MAF0_INFO7_${OUT_STEM}_chr1_*.regenie | sed 's/EXTRA/EXTRA P/g' \
 > regenie_output/ukb_MAF0_INFO7_${OUT_STEM}_chrALL.regenie

for i in {1..22}
do
  printf "chr$i "
  wc -l regenie_output/ukb_MAF0_INFO7_${OUT_STEM}_chr${i}_*.regenie
  sed 1d regenie_output/ukb_MAF0_INFO7_${OUT_STEM}_chr${i}_*.regenie | awk '{print $0,10^(-$13)}' \
   >> regenie_output/ukb_MAF0_INFO7_${OUT_STEM}_chrALL.regenie
done

wc -l regenie_output/ukb_MAF0_INFO7_${OUT_STEM}_chrALL.regenie

head -1 regenie_output/ukb_MAF0_INFO7_${OUT_STEM}_chrALL.regenie \
 > regenie_output/ukb_MAF01_INFO7_${OUT_STEM}_chrALL.regenie
awk '$6>0.01 && $6<0.99 && $7>0.7' regenie_output/ukb_MAF0_INFO7_${OUT_STEM}_chrALL.regenie \
 >> regenie_output/ukb_MAF01_INFO7_${OUT_STEM}_chrALL.regenie

wc -l regenie_output/ukb_MAF01_INFO7_${OUT_STEM}_chrALL.regenie

## Manually do the below once happy with output!
#rm regenie_output/ukb_MAF0_INFO7_${OUT_STEM}_chr*_*.regenie
#gzip regenie_output/ukb_MAF0_INFO7_${OUT_STEM}_chrALL.regenie
