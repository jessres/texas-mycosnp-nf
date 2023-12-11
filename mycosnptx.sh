#!/bin/bash
version="mycosnptx version 1.0"
#author		 :Jessica Respress
#date		 :20230512
#usage		 :bash mycosnptx.sh <run_name>

work_dir=/home/dnalab/Candida_auris
run_dir=$PWD/mycosnp-nf
samplesheet_dir=$PWD/mycosnp-nf/samplesheet
samplesheet=$run_name.csv
run_name=$1
prefix=/home/dnalab/Candida_auris/mycosnp-nf/output/$1

mkdir $run_dir/output
mkdir $run_dir/output/$1
mkdir $run_dir/output/$1/bam
mkdir $run_dir/reads/zip
mkdir $run_dir/reads/$1
mkdir $run_dir/samplesheet
echo "Running "$version > $run_dir/output/$1/mycosnptx.log

for run_name in analysis;
do
#pull fastq files from aws to $PWD/mycosnp-nf/fastq/RAW_RUNS	
echo "Pulling fastq from aws s3 bucket for "$1 && sudo aws s3 cp s3://804609861260-bioinformatics-infectious-disease/Candida/RAW_RUNS/"$1".zip $run_dir/reads/zip  --region us-gov-west-1 &&
echo "Unzip "$1.zip &&
unzip -j $run_dir/reads/zip/$1.zip -d $run_dir/reads/$1 &&
echo "done unzip "$1.zip &&
echo "copy controls"
aws s3 cp s3://804609861260-bioinformatics-infectious-disease/Candida/ref/controls/ $run_dir/reads/$1/ --region us-gov-west-1 --recursive --profile Bacteria_wgs_user &&
echo "done copy controls" 
done

#generate sample sheet
#for samplesheet in samplesheet_dir;
#do
#mkdir $run_dir/samplesheet &&
#echo "Processing run for "$1 && bash mycosnp-nf/bin/mycosnp_full_samplesheet.sh $run_dir/reads/$1 > $samplesheet_dir/$1.csv && echo "Samplesheet generated for "$1 && 
#sudo rm $run_dir/reads/zip/$1.zip
#done
echo "Processing run for "$1 && bash mycosnp-nf/bin/mycosnp_full_samplesheet.sh $run_dir/reads/$1 > $samplesheet_dir/$1.csv && 
echo "Samplesheet generated for "$1 &&
sudo rm $run_dir/reads/zip/$1.zip
#done

#Run Nextflow 
for samplesheet in samplesheet_dir;
do
echo "Running nextflow for run "$1 && nextflow run mycosnp-nf/main.nf -profile singularity --input /$samplesheet_dir/$1.csv --fasta $run_dir/ref/GCA_016772135.1_ASM1677213v1_genomic.fna --outdir $prefix
done

#Process QC report
for data in QC_report;
do
echo "Processing QC output and generating QC_report" && bash qc_report.sh $1 && echo "Merging qc_report with KEY" && cp /home/dnalab/Candida_auris/mycosnp-nf/reads/$1/"$1"_metadata.xlxs $prefix && python qc_report.py $1
done

#Run Kraken 2
#for sequences in run;
#do 
#echo "Preparing samples for Kraken2 analysis" &&
#mkdir $run_dir/output/kraken2_output &&
#mkdir $run_dir/output/kraken1_format &&
#ls -U $run_dir/output/$1/samples > $prefix/sample_name.txt && 
#collecting sample names to run kraken
#cd $prefix &&
#python $work_dir/kraken2_CA.py > /$prefix/"kraken1.tmp" &&
#cat kraken1.tmp | tr -d '[]' | tr -d \' | tr -d \, | tr " " "\n" > $prefix/kraken2.tmp &&
#awk -v prefix="$prefix" '{print prefix $0};' $prefix/kraken2.tmp > $prefix/kraken2.txt && 
#rm $prefix/kraken1.tmp &&
#rm $prefix/kraken2.tmp &&
#python $work_dir/run_kraken2.py &&
#python $work_dir/kraken1_format.py &&
#python $work_dir/Kraken2-output-manipulation/kraken-multiple-taxa.py -d $run_dir/output/kraken1_format/ -r S -c 6 -o $prefix/kraken2_multiply &&
#sed -e "s/\[//g;s/\]//g;s/'//g;s|\t|,|g" $prefix/kraken2_multiply > $prefix/kraken_report_all_table.csv
#done


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
cp -r $prefix/combined/phylogeny/fasttree/ $prefix/ &&
cp -r $prefix/combined/phylogeny/rapidnj/ $prefix/ &&
cp -r $prefix/combined/vcf-to-fasta/ $prefix/ &&
#cp -r $run_dir/output/kraken2_output $prefix/ &&
#cp $run_dir/output/kraken2_report.txt $run_dir/output/$1/ &&
#sudo rm -r $run_dir/output/kraken2_output &&
#sudo rm -r $run_dir/output/kraken1_format &&
#sudo rm cp $run_dir/output/kraken2_report.txt &&
#cd $prefix &&
#zip -r $1".zip" fasttree rapidnj vcf-to-fasta $1"_QCREPORT.txt" kraken_report_all_table.csv &&
zip -r $run_dir/output/$1".zip" $run_dir/output/$1 &&
sudo aws s3 cp $run_dir/output/$1".zip" s3://804609861260-bioinformatics-infectious-disease/Candida/ANALYSIS_RESULT/ --region us-gov-west-1  --profile Bacteria_wgs_user &&
#rm -r fasttree &&
#rm -r rapidnj &&
#rm -r vcf-to-fasta &&
sudo rm -r $work_dir/work &&
mkdir $work_dir/work &&
echo "Analysis Complete!"
done 
