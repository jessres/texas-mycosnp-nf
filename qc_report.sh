#!/bin/bash
version="qc_report.sh version 1.0"
#author		 :Jessica Respress
#date		   :20230517
#usage		 :bash qc_report.sh <run_name>

echo "Running qc_report.sh version %s" >> $run_dir/output/$1/mycosnptx.log
run_dir=$PWD/mycosnp-nf

awk 'BEGIN {FS="\t"};\
	NR==1{$14="Pass/Fail";print;next};\
	$9 > 42 && $9 < 47.5 && $10 >= 28 && $11 >= 20{printf "%s\t%s\n", $0, "PASS"};\
	$9 < 42 || $9 > 47.5 || $10 < 28 || $11 < 20{printf "%s\t%s\n", $0, "FAIL"};' $run_dir/output/$1/stats/qc_report/qc_report.txt > $run_dir/output/$1/$1"_QCREPORT.txt"
