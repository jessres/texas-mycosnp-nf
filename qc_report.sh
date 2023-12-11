#!/bin/bash
version="version 1.0"
#author		 :Jessica Respress
#date		   :20230517
#usage		 :bash qc_report.sh <run_name>

run_dir=$PWD/mycosnp-nf
echo "Running qc_report.sh $version" >> $run_dir/output/$1/mycosnptx.log

awk '(NR>1)' $run_dir/output/$1/stats/qc_report/qc_report.txt > $run_dir/output/$1/$1"_QCREPORT.temp"
awk 'BEGIN {FS="\t"};\
	NR==0{$14="Pass/Fail";print;next};\
	$9 > 42 && $9 < 47.5 && $10 >= 28 && $11 >= 20{printf "%s\t%s\n", $0, "PASS"};\
	$9 < 42 || $9 > 47.5 || $10 < 28 || $11 < 20{printf "%s\t%s\n", $0, "FAIL"};' $run_dir/output/$1/$1"_QCREPORT.temp" > $run_dir/output/$1/$1"_QCREPORT2.temp" 

awk 'BEGIN {FS="\t"};\
  NR==0
	$9 > 42 && $9 < 47.5 && $10 >= 28 && $11 >= 20{printf "%s\t%s\n", $0, " "};\
 	$9 < 42 || $9 > 47.5{printf "%s\t%s\n", $0, "GC_After_Trimming not within 42%-47.5%"};\
 	$10 < 28{printf "%s\t%s\n", $0, "Average_Q_Score_After_Trimming not greater than or equal to 28"};\
	$11 < 20{printf "%s\t%s\n", $0, "Reference_Length_Coverage_After_Trimming not greater than or equal to 20X"};' $run_dir/output/$1/$1"_QCREPORT2.temp"  > $run_dir/output/$1/$1"_QCREPORT3.temp" 
 
 awk 'BEGIN {FS="\t"};\
  {print $1,"\t"$9,"\t"$10,"\t"$11,"\t"$14,"\t"$15};' $run_dir/output/$1/$1"_QCREPORT3.temp"  > $run_dir/output/$1/$1"_QCREPORT4.temp" 

echo "Sample_Name	GC_After_Trimming	Average_Q_Score_After_Trimming	Reference_Length_Coverage_After_Trimming	Pass/Fail	QC_Comment" | cat - $run_dir/output/$1/$1"_QCREPORT4.temp" > $run_dir/output/$1/$1"_QC_REPORT.txt"
#done

rm $run_dir/output/$1/$1"_QCREPORT.temp"
rm $run_dir/output/$1/$1"_QCREPORT2.temp"
rm $run_dir/output/$1/$1"_QCREPORT3.temp"
rm $run_dir/output/$1/$1"_QCREPORT4.temp"
