#!/bin/bash
version="mycosnptx version 1.01"
#author		 :Jessica Respress
#date		 :2024/03/05
#usage		 :bash mycosnptx.sh <run_name>

run_name="$1"
work_dir=/home/dnalab/Candida_auris
run_dir=${PWD}/mycosnp-nf
samplesheet_dir=${PWD}/mycosnp-nf/samplesheet
samplesheet=${run_name}.csv
prefix=/bioinformatics/Candida_auris/mycosnp-nf/output/${run_name}
sra_file=${samplesheet_dir}

mkdir $run_dir/output
mkdir $run_dir/output/${run_name}
#mkdir $run_dir/output/$1/bam
mkdir $run_dir/reads/zip
mkdir $run_dir/reads/${run_name}
mkdir $run_dir/samplesheet
echo "Running "$version > ${prefix}/${run_name}_mycosnptx.log

main () {
#pull fastq files from aws to $PWD/mycosnp-nf/fastq/RAW_RUNS	
  echo "Pulling fastq from aws s3 bucket for "${run_name}
  aws s3 cp s3://804609861260-bioinformatics-infectious-disease/Candida/RAW_RUNS/${run_name}.zip ${run_dir}/reads/zip  --region us-gov-west-1
  echo "Unzip "${run_name}.zip
  unzip -j ${run_dir}/reads/zip/${run_name}.zip -d ${run_dir}/reads/${run_name}
  echo "done unzip "${run_name}.zip
  echo "copy controls"
  aws s3 cp s3://804609861260-bioinformatics-infectious-disease/Candida/ref/controls/ $run_dir/reads/${run_name}/ --region us-gov-west-1 --recursive --profile Bacteria_wgs_user &
  pd_aws_download=$!
  echo "done copy controls" 

#generate sample sheet
  wait ${pd_download}
  if [ -d ${run_dir}/reads/${run_name} ]; then
    echo "Processing run for "${run_name}
    bash mycosnp-nf/bin/mycosnp_full_samplesheet.sh ${run_dir}/reads/${run_name} > ${samplesheet_dir}/${run_name}.csv &
    pd_samplesheet=$!
    wait ${pd_samplesheet}
    echo "Samplesheet generated for "${run_name}
    rm ${run_dir}/reads/zip/${run_name}.zip &
    pd_delete=$!
  else 
    echo "Failed to generate samplesheet."
    exit 1
  fi

#Run Nextflow 
  wait ${pd_delete}
  if [ $? -eq 0 ] && [ -e "${samplesheet_dir}/${run_name}.csv" ]; then
    echo "Running nextflow for run "${run_name}
    (nextflow run mycosnp-nf/main.nf -profile singularity --input ${samplesheet_dir}/${run_name}.csv --fasta ${run_dir}/ref/GCA_016772135.1_ASM1677213v1_genomic.fna --outdir ${prefix}) &
    pd_mycosnp=$!
  else
    echo "MycoSNP failed to run"
    exit 1
  fi

#Process QC report
  wait ${pd_mycosnp}
  if [ -e "${prefix}/stats/qc_report/qc_report.txt" ]; then 
    echo "Processing QC output and generating QC_report"
    bash /home/dnalab/Candida_auris/scripts/qc_report.sh ${run_name} &
    pd_qc=$!
    wait ${pd_qc}
    echo "Merging qc_report with KEY"
    cp /home/dnalab/Candida_auris/mycosnp-nf/reads/${run_name}/${run_name}_metadata.xlxs ${prefix}
    python /home/dnalab/Candida_auris/scripts/qc_report.py ${run_name} &
    pd_qc2=$!
  else 
    echo "Unable to locate qc_report.txt"
    exit 1
  fi

#Upload QC results to AWS
  wait ${pd_qc2}
  if [ $? -eq 0 ] && [ -e "${prefix}/combined/phylogeny/fasttree/" ] && [ -e "${prefix}/combined/phylogeny/rapidnj/" ] && [ -e "${prefix}/combined/vcf-to-fasta/" ]; then
    echo "Collect, compress and upload analysis results to aws s3 bucket"
    cp -r ${prefix}/combined/phylogeny/fasttree/ ${prefix}/ 
    cp -r ${prefix}/combined/phylogeny/rapidnj/ ${prefix}/ 
    cp -r ${prefix}/combined/vcf-to-fasta/ ${prefix}/
    zip -r ${run_dir}/output/${run_name}".zip" ${run_dir}/output/${run_name}
    aws s3 cp ${run_dir}/output/${run_name}".zip" s3://804609861260-bioinformatics-infectious-disease/Candida/ANALYSIS_RESULT/ --region us-gov-west-1  --profile Bacteria_wgs_user &
    pd_aws=$!
    wait ${pd_aws}
    sudo rm -r ${work_dir}/work
    mkdir ${work_dir}/work
    echo "Output uploaded to aws!"
  else
    echo "Ouput files to upload not found."
    exit 1
  fi 

#Run script to set up NCBI submission 
  wait ${pd_aws}
  if [ $? -eq 0 ] && [ -e "${run_dir}/output/${run_name}/${run_name}_QC_REPORT.txt" ]; then
    echo "Preparing fastq files and metadata file for SRA submission."
    python /home/dnalab/Candida_auris/post_mycosnptx.py ${run_name} 
  else 
    echo "NCBI prep failed."
    exit 1
  fi
}
(main 2>&1 | tee "${run_name}_mycosnptx.log") & disown 
sleep 2
echo "Function is running in background."
