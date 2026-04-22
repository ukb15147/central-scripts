#!/bin/bash -l
#SBATCH --partition=cpu
#SBATCH --output=/scratch/prj/derm_ukb/assoc_genome_wide/sbatch_logs/%u_%A_%a.out
#SBATCH --time=2-0
#SBATCH --mem=60gb
#SBATCH --ntasks=4
#SBATCH --nodes=1
#SBATCH --array=1-22

plink(){
 /scratch/prj/derm_ukb/software/plink2 "$@"
}

CHR=$SLURM_ARRAY_TASK_ID
GROUPDIR="/scratch/prj/derm_ukb/"




if [ "$#" -ne 4 ]; then
    echo "   ######## Three command line arguments required"
    echo "   ########  1. Input phenotype file"
    echo "   ########  2. Input covariate file"
    echo "   ########  3. Latest UKB withdrawals list (see withdrawals dir)"
    echo "   ########  4. Output stem"
    exit
fi

echo "Command line arguments accepted"


PHENO=$1
COVS=$2
WITHD=$3
OUTPUT=$4

if [ ${CHR} -eq 1 ]; then
 echo Command line arguments for script1 ${0} > output/${OUTPUT}.script1.commandargs
 echo 1 ${PHENO} >> output/${OUTPUT}.script1.commandargs
 echo 2 ${COVS} >> output/${OUTPUT}.script1.commandargs
 echo 3 ${WITHD} >> output/${OUTPUT}.script1.commandargs
 echo 4 ${OUTPUT} >> output/${OUTPUT}.script1.commandargs
 echo >> output/${OUTPUT}.script1.commandargs
 echo Built in arguments for script1 >> output/${OUTPUT}.script1.commandargs
 echo Covariates ${COVS} >> output/${OUTPUT}.script1.commandargs
fi

echo "PLINK processing started"

plink \
--pgen ${GROUPDIR}/ukb_imputed_geno_data/ukb15147_imp_whiteBrit_unrel_MAF0_005_INFO7_chr${CHR}.pgen \
--pvar ${GROUPDIR}/ukb_imputed_geno_data/ukb15147_imp_whiteBrit_unrel_MAF0_005_INFO7_chr${CHR}.pvar \
--psam ${GROUPDIR}/ukb_imputed_geno_data/ukb15147_imp_whiteBrit_unrel_MAF0_005_INFO7.psam \
--pheno ${PHENO} \
--remove ${WITHD} \
--glm hide-covar cols=+a1freq,+a1freqcc,+machr2,+ax \
--covar ${COVS} \
--ci 0.95 \
--out output/${OUTPUT}_chr${CHR}


echo "PLINK processing complete. Proceeding to clump association results"

## Extract significant SNPs at P<=1e-4 but mark duplicate SNPs because clump can't distinguish
head -1 output/${OUTPUT}_chr${CHR}.PHENO1.glm.logistic.hybrid |\
 awk 'OFS="\t"{print $0,"ID_ALT"}' > output/${OUTPUT}_chr${CHR}.tmp
sed 1d output/${OUTPUT}_chr${CHR}.PHENO1.glm.logistic.hybrid |\
 awk 'OFS="\t"{b=$3
      if($3 in a){
        x=$3
        $3=$3"_"a[x]
        a[x]=a[x]+1
      }else{
        a[$3]=1
      }
      if($20 <= 1e-4){
       print $0,b
      }}' >> output/${OUTPUT}_chr${CHR}.tmp

cut -f22 output/${OUTPUT}_chr${CHR}.tmp > output/${OUTPUT}_chr${CHR}.tmp.extract

plink \
--pgen ${GROUPDIR}/ukb_imputed_geno_data/ukb15147_imp_whiteBrit_unrel_MAF0_005_INFO7_chr${CHR}.pgen \
--pvar ${GROUPDIR}/ukb_imputed_geno_data/ukb15147_imp_whiteBrit_unrel_MAF0_005_INFO7_chr${CHR}.pvar \
--psam ${GROUPDIR}/ukb_imputed_geno_data/ukb15147_imp_whiteBrit_unrel_MAF0_005_INFO7.psam \
--remove ${WITHD} \
--extract output/${OUTPUT}_chr${CHR}.tmp.extract \
--make-bed \
--out output/${OUTPUT}_chr${CHR}.tmp.PLINK1

## Ensure duplicate SNPs are named correctly
awk 'OFS="\t"{if($2 in a){
        x=$2
        $2=$2"_"a[x]
        a[x]=a[x]+1
      }else{
        a[$2]=1
      }
      print $0}' output/${OUTPUT}_chr${CHR}.tmp.PLINK1.bim \
 > output/${OUTPUT}_chr${CHR}.tmp.PLINK1.bim2

mv output/${OUTPUT}_chr${CHR}.tmp.PLINK1.bim2 output/${OUTPUT}_chr${CHR}.tmp.PLINK1.bim

## Switch to plink 1.9
plink(){
 /scratch/prj/derm_ukb/software/plink "$@"
}

plink \
--bfile output/${OUTPUT}_chr${CHR}.tmp.PLINK1 \
--clump output/${OUTPUT}_chr${CHR}.tmp \
--clump-p1 1e-5 \
--clump-p2 1e-4 \
--clump-kb 500 \
--clump-r2 0.1 \
--clump-allow-overlap \
--clump-snp-field ID \
--out output/${OUTPUT}_chr${CHR}_clumped

rm output/${OUTPUT}_chr${CHR}.tmp output/${OUTPUT}_chr${CHR}.tmp.extract \
 output/${OUTPUT}_chr${CHR}.tmp.PLINK1.bed \
 output/${OUTPUT}_chr${CHR}.tmp.PLINK1.bim output/${OUTPUT}_chr${CHR}.tmp.PLINK1.fam

echo "Clumping complete"

