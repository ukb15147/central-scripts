#!/bin/env bash
#$ -cwd
#$ -q HighMemLongterm.q,HighMemShortterm.q,LowMemLongterm.q,LowMemShortterm.q


## Create a link to the authentication key - received by email from UKB

ln -s ../../k15147.key .ukbkey


## Run interactively:

## fam file
../../helpers/ukbgene cal -c1 -m

for i in $(seq 2 22; echo X Y XY MT); do
 ln -s ukb15147_cal_chr1_v2_s488288.fam ukb15147_cal_chr${i}_v2_s488288.fam
done


## relatedness files
../../helpers/ukbgene rel

## imputation sample
../../helpers/ukbgene imp -c1 -m
