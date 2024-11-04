#!/bin/env bash
#$ -cwd
#$ -j y  ## Set to n to separate stdout and stderr
#$ -q HighMemLongterm.q,LowMemLongterm.q,LowMemShortterm.q

## load any modules you need 
module load bioinformatics/plink2/1.90b3.38


## Steps:
## 1. get list of non-Eur, highly related, sex discordant and high het/miss - add to exclusion file
## 2. investigate call rate in remaining and add to exclusion file
## 3. create reduced relatedness file with remaining samples and look at second-degree rels


##---##
## 1 ##
##---##

paste -d" " ukb_June2017_fullgeno_15147.fam link_to_ukb_sqc_v2.txt > samples_with_qc.txt

## Non-Europeans
awk -F" " '$30!=1{print $1,$2}' samples_with_qc.txt > exclusions_nonEur.remove

## Gender mismatch
awk -F" " '$16!=$17{print $1,$2}' samples_with_qc.txt > exclusions_gender.remove

## Excess relatives
awk -F" " '$29==1{print $1,$2}' samples_with_qc.txt > exclusions_excessRels.remove

## Call rate < 0.95
awk -F" " '$22>=0.05{print $1,$2}' samples_with_qc.txt > exclusions_lowCallRate.remove

## Excess heterozygosity/missingness
awk -F" " '$25==1{print $1,$2}' samples_with_qc.txt > exclusions_excessHetMiss.remove

## Used in PCA - this should give us an unrelated subset as defined by UK Biobank
awk -F" " '$31!=1{print $1,$2}' samples_with_qc.txt > exclusions_exclFromPCA.remove


## Combine
cat exclusions_nonEur.remove exclusions_gender.remove exclusions_excessRels.remove \
 exclusions_lowCallRate.remove exclusions_excessHetMiss.remove exclusions_exclFromPCA.remove |\
 sort -u > exclusions_combined1.remove


## Get an extracted dataset after making these initial exclusions
plink \
--allow-no-sex \
--bfile ukb_June2017_fullgeno_15147 \
--remove exclusions_combined1.remove \
--make-bed \
--out ukb_step1_initial_exclusions


##---##
## 2 ##
##---##

## Check missing rates - interested in low quality SNPs specifically
plink \
--allow-no-sex \
--bfile ukb_step1_initial_exclusions \
--missing \
--out ukb_step1_initial_exclusions_miss


## Remove poor performing SNPs and repeat missing rates
plink \
--allow-no-sex \
--bfile ukb_step1_initial_exclusions \
--geno 0.1 \
--make-bed \
--out ukb_step2_excl_worst_SNPs

plink \
--allow-no-sex \
--bfile ukb_step2_excl_worst_SNPs \
--missing \
--out ukb_step2_excl_worst_SNPs_miss

rm ukb_step1_initial_exclusions.bed
touch ukb_step1_initial_exclusions_REMOVED.bed


## Remove samples with >2% missingness in the remaining "good" SNPs
sed 1d ukb_step2_excl_worst_SNPs_miss.imiss |\
 awk '$6>0.02{print $1,$2}' > exclusions_round2_callRate.remove

plink \
--allow-no-sex \
--bfile ukb_step2_excl_worst_SNPs \
--remove exclusions_round2_callRate.remove \
--make-bed \
--out ukb_step3_excl_remainingLowCallSamples

rm ukb_step2_excl_worst_SNPs.bed
touch ukb_step2_excl_worst_SNPs_REMOVED.bed


## Remove SNPs genotyped with call rate < 0.95 in this dataset
plink \
--allow-no-sex \
--bfile ukb_step3_excl_remainingLowCallSamples \
--geno 0.05 \
--make-bed \
--out ukb_step4_interim

plink \
--allow-no-sex \
--bfile ukb_step4_interim \
--missing \
--out ukb_step4_interim_miss

rm ukb_step3_excl_remainingLowCallSamples.bed
touch ukb_step3_excl_remainingLowCallSamples_REMOVED.bed


##---##
## 3 ##
##---##

## Run KING in separate script, including generating pruned dataset

## Checked and no remaining relatives found at degree 2 or closer
