#!/bin/bash -l
#SBATCH -p cpu
#SBATCH --output=/scratch/users/%u/000_sbatch_job_output/%j.out
#SBATCH --time=2-0  # Maximum of 2 days (instead of default 1)
#SBATCH --mem=8gb  # Mem of 40 GB (instead of default 1GB)
# #SBATCH --ntasks=4
# #SBATCH --nodes=1

awk 'BEGIN { OFS=" " }
{ printf "%s%s", (FNR>1 ? OFS : ""), $ARGIND }
ENDFILE {
    print ""
    if (ARGIND < NF) {
        ARGV[ARGC] = FILENAME
        ARGC++
    }
}' ukb_hla_v2.txt |\
 awk '{$1=$1" P A"; print $0}' \
 > ukb_hla_v2_transposed.dosage
