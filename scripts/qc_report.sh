#!/bin/bash
version="version 1.0"
#author		 :Jessica Respress
#date		   :20230517
#usage		 :bash qc_report.sh <run_name>
#Note      :This is used to generate a summarized QC report.

prefix=/bioinformatics/Candida_auris/mycosnp-nf/output/$1
run_dir=$PWD/mycosnp-nf
echo "Running qc_report.sh $version" >> ${prefix}/mycosnptx.log

awk '(NR>1)' ${prefix}/stats/qc_report/qc_report.txt > ${prefix}/$1"_QCREPORT.temp"
awk '!/SRR/' ${prefix}/$1"_QCREPORT.temp" > ${prefix}/$1"_QCREPORT2.temp" 
awk 'BEGIN {FS="\t"};\
	NR==0{$14="Pass/Fail";print;next};\
	$9 > 42 && $9 < 47.5 && $10 >= 28 && $11 >= 20{printf "%s\t%s\n", $0, "PASS"};\
	$9 < 42 || $9 > 47.5 || $10 < 28 || $11 < 20{printf "%s\t%s\n", $0, "FAIL"};' ${prefix}/$1"_QCREPORT2.temp" > ${prefix}/$1"_QCREPORT3.temp" 

awk 'BEGIN {FS="\t"};\
  NR==0
	$9 > 42 && $9 < 47.5 && $10 >= 28 && $11 >= 20{printf "%s\t%s\n", $0, " "};\
 	$9 < 42 || $9 > 47.5{printf "%s\t%s\n", $0, "GC_After_Trimming not within 42%-47.5%"};\
 	$10 < 28{printf "%s\t%s\n", $0, "Average_Q_Score_After_Trimming not greater than or equal to 28"};\
	$11 < 20{printf "%s\t%s\n", $0, "Reference_Length_Coverage_After_Trimming not greater than or equal to 20X"};' ${prefix}/$1"_QCREPORT3.temp" > ${prefix}/$1"_QCREPORT4.temp" 
 
 awk 'BEGIN {FS="\t"};\
  {print $1,"\t"$9,"\t"$10,"\t"$11,"\t"$14,"\t"$15};' ${prefix}/$1"_QCREPORT4.temp"  > ${prefix}/$1"_QCREPORT5.temp" 

echo "Sample_Name	GC_After_Trimming	Average_Q_Score_After_Trimming	Reference_Length_Coverage_After_Trimming	Pass/Fail	QC_Comment" | cat - ${prefix}/$1"_QCREPORT5.temp" > ${prefix}/$1"_QC_REPORT.txt"
#done

rm ${prefix}/$1"_QCREPORT.temp"
rm ${prefix}/$1"_QCREPORT2.temp"
rm ${prefix}/$1"_QCREPORT3.temp"
rm ${prefix}/$1"_QCREPORT4.temp"
rm ${prefix}/$1"_QCREPORT5.temp"
