#!/bin/bash
version="mycosnptx version 1.0"
#author		 :Jessica Respress
#date		   :20230512
#usage		 :bash mycosnptx.sh <run_name>

run_dir=$PWD/mycosnp-nf
samplesheet_dir=$PWD/mycosnp-nf/samplesheet
samplesheet=$run_name.csv
run_name=$1

mkdir $run_dir/output
mkdir $run_dir/output/$1
echo "Running "$version > $run_dir/output/$1/mycosnptx.log

for run_name in analysis;
do
#pull fastq files from aws to $PWD/mycosnp-nf/fastq/RAW_RUNS	
echo "Pulling fastq from aws s3 bucket for "$1 && sudo aws s3 cp s3://804609861260-bioinformatics-infectious-disease/Candida/RAW_RUNS/"$1".zip /home/jessr/mycosnp-nf/reads/zip --profile Bacteria_wgs_user &&
echo "Unzip "$1.zip &&
mkdir $run_dir/reads/$1 &&
unzip -j $run_dir/reads/zip/$1.zip -d $run_dir/reads/$1
done

#generate sample sheet
for samplesheet in samplesheet_dir;
do
#mkdir $run_dir/samplesheet &&
echo "Processing run for "$1 && bash mycosnp-nf/bin/mycosnp_full_samplesheet.sh $run_dir/reads/$1 > $samplesheet_dir/$1.csv && echo "Samplesheet generated for "$1 && 
sudo rm $run_dir/reads/zip/$1.zip
done

#Run Nextflow 
for samplesheet in samplesheet_dir;
do
echo "Running nextflow for run "$1 && /home/jessr/nextflow run mycosnp-nf/main.nf -profile singularity --input /$samplesheet_dir/$1.csv --fasta $run_dir/ref/GCA_016772135.1_ASM1677213v1_genomic.fna --outdir $run_dir/output/$1
done

#Process QC report
for data in QC_report;
do
echo "Processing QC output and generating QC_report" && bash qc_report.sh $1
done
