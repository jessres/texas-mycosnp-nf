#!/bin/bash
version="mycosnptx version 1.0"
#author		 :Jessica Respress
#date		 :20230512
#usage		 :bash mycosnptx.sh <run_name>

run_dir=$PWD/mycosnp-nf
samplesheet_dir=$PWD/mycosnp-nf/samplesheet
samplesheet=$run_name.csv
run_name=$1
prefix=/home/jessr/mycosnp-nf/output/$1/

mkdir $run_dir/output
mkdir $run_dir/output/$1
mkdir $run_dir/output/$1/bam
mkdir $run_dir/reads/zip
echo "Running "$version > $run_dir/output/$1/mycosnptx.log

for run_name in analysis;
do
#pull fastq files from aws to $PWD/mycosnp-nf/fastq/RAW_RUNS	
echo "Pulling fastq from aws s3 bucket for "$1 && sudo aws s3 cp s3://804609861260-bioinformatics-infectious-disease/Candida/RAW_RUNS/"$1".zip $run_dir/reads/zip --profile Bacteria_wgs_user --region us-gov-west-1 &&
echo "Unzip "$1.zip &&
mkdir $run_dir/reads/$1 &&
unzip -j $run_dir/reads/zip/$1.zip -d $run_dir/reads/$1 &&
sudo aws s3 cp s3://804609861260-bioinformatics-infectious-disease/Candida/ref/controls/ $run_dir/reads/$1/ --recursive --region us-gov-west-1 --profile Bacteria_wgs_user
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
echo "Running nextflow for run "$1 && /home/jessr/nextflow run mycosnp-nf/main.nf -profile singularity --input /$samplesheet_dir/$1.csv --fasta /home/jessr/mycosnp-nf/ref/GCA_016772135.1_ASM1677213v1_genomic.fna --outdir $run_dir/output/$1
done

#Process QC report
for data in QC_report;
do
echo "Processing QC output and generating QC_report" && bash qc_report.sh $1
done

#Run Kraken 2
for sequences in run;
do 
echo "Preparing samples for Kraken2 analysis" &&
cd $run_dir/output/$1 &&
#collecting sample names to run kraken
python /home/jessr/kraken2_CA.py > /$run_dir/output/$1/"kraken1.tmp"
cat kraken1.tmp | tr -d '[]' | tr -d \' | tr -d \, | tr " " "\n" > kraken2.tmp &&
awk -v prefix="$prefix" '{print prefix $0};' $run_dir/output/$1/kraken2.tmp > $run_dir/output/$1/kraken2.txt &&
rm kraken1.tmp
rm kraken2.tmp
python run_kraken2.py 
done

#Copy .bam files for aws s3 upload
#for bam in samples;
#do
#echo "Prepare analysis results for SRA submission and upload to aws" &&
#cp $run_dir/output/$1/samples/*/finalbam/* $run_dir/output/$1/bam &&
#zip -jr $1".zip" /home/jessr/mycosnp-nf/output/CA_230519_M06018/bam/ &&
#sudo aws s3 cp $run_dir/output/$1/bam/$1".zip" s3://804609861260-bioinformatics-infectious-disease/Candida/ANALYSIS_RESULT/ --region us-gov-west-1
#done

#Upload QC results to AWS 
for results in combined;
do
echo "Collect, compress and upload analysis results to aws s3 bucket" &&
cp -r $run_dir/output/$1/combined/phylogeny/fasttree/ $run_dir/output/$1/ &&
cp -r $run_dir/output/$1/combined/phylogeny/rapidnj/ $run_dir/output/$1/ &&
cp -r $run_dir/output/$1/combined/vcf-to-fasta/ $run_dir/output/$1/ &&
cp $run_dir/output/kraken2_output.txt $run_dir/output/$1/ &&
cp $run_dir/output/kraken2_report.txt $run_dir/output/$1/ &&
sudo rm $run_dir/output/kraken2_output.txt &&
sudo rm cp $run_dir/output/kraken2_report.txt &&
cd $run_dir/output/$1 &&
zip -r $1".zip" fasttree rapidnj vcf-to-fasta $1"_QCREPORT.txt" kraken2_output.txt kraken2_report.txt &&
sudo aws s3 cp $1".zip" s3://804609861260-bioinformatics-infectious-disease/Candida/REPORT/ --region us-gov-west-1 &&
rm -r fasttree &&
rm -r rapidnj &&
rm -r vcf-to-fasta &&
cd /home/jessr
done

echo "Analysis Complete!"
done 
