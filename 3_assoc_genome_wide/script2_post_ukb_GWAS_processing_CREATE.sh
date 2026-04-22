#!/bin/bash -l
#SBATCH --partition=cpu,simpson_cpu
#SBATCH --output=/scratch/prj/derm_ukb/assoc_genome_wide/sbatch_logs/script2_%u_%j.out
#SBATCH --time=2-0
#SBATCH --mem=10gb
#SBATCH --ntasks=4
#SBATCH --nodes=1
#SBATCH --export=ALL
# #SBATCH --array=1-22

if [ "$#" -ne 3 ]; then
    echo "   ######## Three command line arguments required"
    echo "   ########  1. Output file (*.hybrid) for chromosome 1"
    echo "   ########     OR merged file (*.hybrid.gz) if this script already run once."
    echo "   ########  2. List of existing regions for trait (two columns: chr pos)"
    echo "   ########     or empty file if none (e.g. plot_regions/empty_regions)"
    echo "   ########  3. Title for Manhattan and QQ plots (enclose in single"
    echo "   ########     quotes if spaces)"
    exit
fi

echo "Script to process UKB GWAS results in standard pipeline."
echo "Note that it no longer requires user to have installed R package 'plotrix' but you should have preinstalled the ldsc conda environment (see README)"

echo "Command line arguments accepted"
python --version
KNOWN=$2
TITLE=$3

fileRegex=".*chr1.*"

if [[ $1 =~ $fileRegex ]]; then

 CHR1=$1
 ## This now replaced with more flexible regex: STEM=$(echo ${CHR1} | sed 's/_chr1.PHENO1.glm.logistic.hybrid//')
 STEM=$(echo ${CHR1} | sed 's/_chr1\..*\.glm\.logistic\.hybrid//')
 TAIL=$(echo ${CHR1} | sed "s:${STEM}_chr1::")

 echo "Merging chromosome results. Writing new output with stem: ${STEM}"


 ## Combine output into a single zipped file
 ##-----------------------------------------

 head -1 ${CHR1} > ${STEM}${TAIL}

 for i in $(seq 1 22); do
  grep -v "^#" ${STEM}_chr${i}${TAIL} \
   >> ${STEM}${TAIL}
 done

 COUNT1=$(( $(cat ${STEM}_chr*${TAIL} | wc -l) - 21 ))
 COUNT2=$(cat ${STEM}${TAIL} | wc -l)

 if [ ${COUNT1} -eq ${COUNT2} ]; then
  gzip ${STEM}${TAIL}
  rm ${STEM}_chr*${TAIL}
 else
  echo "   ######## Problem merging PLINK output to file:"
  echo "   ######## ${STEM}${TAIL}"
  exit
 fi

 ## Extract case and control numbers as we will need later
 NUMS=$(grep "controls remaining after main filters." ${STEM}_chr1.log |\
  sed 's/controls remaining after main filters./controls_remaining_after_main_filters./' |\
  sed 's/cases and/cases_and/' |\
  awk '{if($2=="cases_and" && $4=="controls_remaining_after_main_filters."){
          print $1,$3
        }else{
          print "ERROR"
        }
       }END{if(NR==0){print "ERROR"}}')

 if [ "${NUMS}" = "ERROR" ]; then
  echo "   ######## Problem counting cases and controls. Stopping"
  exit
 fi

 ## Archive the logs
 mkdir ${STEM}_plink_logs
 mv ${STEM}_chr*.log ${STEM}_plink_logs/

else

 MERGED=$1
 ## This now replaced with more flexible regex: STEM=$(echo ${MERGED} | sed 's/.PHENO1.glm.logistic.hybrid.gz//')
 STEM=$(echo ${MERGED} | sed 's/\.[^\.]*\.glm\.logistic\.hybrid.gz//')
 TAIL=$(echo ${MERGED} | sed "s:${STEM}::" | sed 's/\.gz//')

 echo "Chromosome results already merged. Summary results will be written with stem ${STEM}"

 STEM_NODIR=$(echo ${STEM} | sed 's:output/::')

 ## Extract case and control numbers as we will need later (as above)
 NUMS=$(grep "controls remaining after main filters." \
         ${STEM}_plink_logs/${STEM_NODIR}_chr1.log |\
  sed 's/controls remaining after main filters./controls_remaining_after_main_filters./' |\
  sed 's/cases and/cases_and/' |\
  awk '{if($2=="cases_and" && $4=="controls_remaining_after_main_filters."){
          print $1,$3
        }else{
          print "ERROR"
        }
       }END{if(NR==0){print "ERROR"}}')

 if [ "${NUMS}" = "ERROR" ]; then
  echo "   ######## Problem counting cases and controls. Stopping"
  exit
 fi

fi

echo we get stem ${STEM} and nums ${NUMS}
#exit

## Calculate LDSC intercept
##-------------------------

echo -e "\nSwitching conda environment for LDSC... \n"
#module load anaconda3/2022.10-gcc-10.3.0
module load anaconda3/2022.10-gcc-13.2.0
source activate ldsc

python --version

echo -e "\nMunging... \n"
../software/ldsc/munge_sumstats.py \
--sumstats ${STEM}${TAIL}.gz \
--N-cas $(echo ${NUMS} | awk '{print $1}') \
--N-con $(echo ${NUMS} | awk '{print $2}') \
--out ${STEM}_munged \
--merge-alleles ../repository/ldsc_ref/w_hm3.snplist \
--snp ID \
--a1 A1 \
--a2 AX \
--p P \
--frq A1_FREQ \
--signed-sumstats OR,1 \
--info MACH_R2 \
--chunksize 500000

## Not sure why these lines were here. My inference now is that munge_stats was producing something
## that claimed to be gzipped but wasn't. I don't hink that is any longer the case so not needed.
#ls ${STEM}_munged*
#mv ${STEM}_munged.sumstats.gz ${STEM}_munged.sumstats
#gzip ${STEM}_munged.sumstats

echo -e "\nCalculating intercept... \n"
../software/ldsc/ldsc.py \
--h2 ${STEM}_munged.sumstats.gz \
--ref-ld-chr ../repository/ldsc_ref/eur_w_ld_chr/ \
--w-ld-chr ../repository/ldsc_ref/eur_w_ld_chr/ \
--out ${STEM}_h2

conda deactivate


## Calculate lambda values
##------------------------

echo -e "\nCalculating lambda values... \n"

zcat ${STEM}${TAIL}.gz |\
 awk 'F==1{a[$1]=$1}F==2{if($3 in a){print $3,$20}}' \
  F=1 ../repository/independent_vars/indep_vars_1500_150_0.2_maf0.01.prune.in F=2 - \
  > ${STEM}_indep_SNP_Pvals

module load r/4.2.2-gcc-10.3.0-withx-rmath-standalone-python3+-chk-version
export R_LIBS="/scratch/prj/derm_ukb/software/R/x86_64-pc-linux-gnu-library/4.2"

python --version
Rscript ../repository/utility_scripts/lambda_gc.R \
 ${STEM}_indep_SNP_Pvals FALSE 2 ${NUMS}

rm ${STEM}_indep_SNP_Pvals


## Generate Manhattan plot
##------------------------
echo -e "\nGenerating manhattan... \n"
## Make regions file combining known and new associations
echo -e "CHROM\tSTART\tEND\tCOLOR" > ${STEM}.regions

## Add green regions for new associations
awk 'OFS="\t"{if(NF>0 && $1!="CHR" && $5<=5e-8){print $1,$4-500000,$4+500000,"#2ca25f"}}' \
 ${STEM}_chr*_clumped.clumped >> ${STEM}.regions

## Merge the clumped files, as we are reading them anyway...
cat ${STEM}_chr*_clumped.clumped | grep CHR | sed 's/ \+/ /g' | sort -u | sed 's/^ //g' \
 > ${STEM}_all.clumped
cat ${STEM}_chr*_clumped.clumped | grep -v CHR | awk 'NF>0' | sed 's/ \+/ /g' | sed 's/^ //g' \
 >> ${STEM}_all.clumped

## Add red regions for known associations
awk 'OFS="\t"{print $1,$2-500000,$2+500000,"#de2d26"}' ${KNOWN} >> ${STEM}.regions

## Generate the plot

Rscript ../repository/utility_scripts/generate_manhattan_plot_v1.R \
 ${STEM}${TAIL}.gz 1 2 20 ${STEM}.regions "${TITLE}" ${STEM}_manhattan.png 1

python --version
## Generate QQ plot
##-----------------
echo -e "\nGenerating QQ plot... \n"
Rscript ../repository/utility_scripts/generate_qqplot_v1.R \
 ${STEM}${TAIL}.gz 20 "${TITLE}" ${STEM}_qq.png

