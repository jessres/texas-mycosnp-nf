#!/bin/bash
version="version 1.0"
#author		 :Jessica Respress
#date		   :20230517
#usage		 :bash qc_report.sh <run_name>

run_dir=$PWD/mycosnp-nf
echo "Running qc_report.sh $version" >> $run_dir/output/$1/mycosnptx.log


awk 'BEGIN {FS="\t"};\
	NR==1{$14="Pass/Fail";print;next};\
	$9 > 42 && $9 < 47.5 && $10 >= 28 && $11 >= 20{printf "%s\t%s\n", $0, "PASS"};\
	$9 < 42 || $9 > 47.5 || $10 < 28 || $11 < 20{printf "%s\t%s\n", $0, "FAIL"};' $run_dir/output/$1/stats/qc_report/qc_report.txt > $run_dir/output/$1/$1"_QCREPORT.temp"
 
awk '(NR>1)' $run_dir/output/$1/$1"_QCREPORT.temp" > $run_dir/output/$1/$1"_QCREPORT2.temp" 

awk 'BEGIN {FS="\t"};\
  NR==2
	$9 > 42 && $9 < 47.5 && $10 >= 28 && $11 >= 20{printf "%s\t%s\n", $0, " "};\
 	$9 < 42 || $9 > 47.5{printf "%s\t%s\n", $0, "GC_After_Trimming not within 42%-47.5%"};\
 	$10 < 28{printf "%s\t%s\n", $0, "Average_Q_Score_After_Trimming not greater than or equal to 28"};\
	$11 < 20{printf "%s\t%s\n", $0, "Reference_Length_Coverage_After_Trimming not greater than or equal to 20X"};' $run_dir/output/$1/$1"_QCREPORT2.temp" > $run_dir/output/$1/$1"_QCREPORT3.temp"

echo "Sample_Name	Reads_Before_Trimming	GC_Before_Trimming	Average_Q_Score_Before_Trimming	Reference_Length_Coverage_Before_Trimming	Reads_After_Trimming	Paired_Reads_After_Trimming	Unpaired_Reads_After_Trimming	GC_After_Trimming	Average_Q_Score_After_Trimming	Reference_Length_Coverage_After_Trimming	Mean_Coverage_Depth	Reads_Mapped	Pass/Fail  Comments" | cat - $run_dir/output/$1/$1"_QCREPORT3.temp" > $run_dir/output/$1/$1"_QCREPORT.txt"


rm $run_dir/output/$1/$1"_QCREPORT.temp"
rm $run_dir/output/$1/$1"_QCREPORT2.temp"
rm $run_dir/output/$1/$1"_QCREPORT3.temp"
