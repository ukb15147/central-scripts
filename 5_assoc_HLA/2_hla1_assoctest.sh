#!/bin/bash -l
#SBATCH --partition=cpu
#SBATCH --output=/scratch/prj/derm_ukb/assoc_genome_wide/sbatch_logs/hla1_%u_%A_%a.out
#SBATCH --time=2-0
#SBATCH --mem=60gb
#SBATCH --ntasks=4
#SBATCH --nodes=1

plink(){
 /scratch/prj/derm_ukb/software/plink "$@"
}

if [ "$#" -ne 3 ]; then
    echo "   ######## Three command line arguments required"
    echo "   ########  1. Input phenotype file"
    echo "   ########  2. Latest UKB withdrawals list (see withdrawals dir)"
    echo "   ########  3. Output stem"
    exit
fi

echo "Command line arguments accepted"

PHENO=$1
WITHD=$2
OUTPUT=$3

echo Command line arguments for hla1 > output/${OUTPUT}.hla1.commandargs
echo 1 ${PHENO} >> output/${OUTPUT}.hla1.commandargs
echo 2 ${WITHD} >> output/${OUTPUT}.hla1.commandargs
echo 3 ${OUTPUT} >> output/${OUTPUT}.hla1.commandargs
echo >> output/${OUTPUT}.hla1.commandargs
echo Built in arguments for hla1 >> output/${OUTPUT}.hla1.commandargs
echo Covariates ${GROUPDIR}/ukb_genotype_data/samples_20PCs_array.covar >> output/${OUTPUT}.hla1.commandargs

echo "PLINK processing started"

plink \
--dosage /scratch/prj/derm_ukb/ukb_hla_data/ukb_hla_v2_transposed.dosage noheader format=1 \
--fam /scratch/prj/derm_ukb/ukb_genotype_data/ukb_June2017_fullgeno_15147.fam \
--pheno ${PHENO} \
--remove ${WITHD} \
--covar /scratch/prj/derm_ukb/ukb_genotype_data/samples_20PCs_array.covar \
--out output/${OUTPUT}_hla

echo "Processing complete"

