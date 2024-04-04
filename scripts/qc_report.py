#!/usr/bin/env python3
version="qc report version 1.0"
#author		 :Jessica Respress
#date		 :20231106
#usage		 :python qc_report.py <run_name>
#Note    : This is used to match sample names with associated WGS_ID using the metadata file and QC_report.txt

from fnmatch import fnmatch
import glob
import pandas as pd
from glob import glob as my_glob
from os import path
from datetime import date
import sys

def prep_qc_report(results, run_name):
    results = pd.read_csv("/bioinformatics/Candida_auris/mycosnp-nf/output/{}/{}".format(run_name,results), sep="\t", header=0, index_col=False, dtype=str)
    results.rename(columns=lambda x: x.strip(), inplace=True)
    results['Sample_Name'] = results['Sample_Name'].apply(lambda x: x.strip())
    results['WGS_ID_TX'] = results['Sample_Name'].str.extract(r'(TX-DSHS-CAU-[A-Za-z0-9]+)')
    results['WGS_ID_CONC'] = results['Sample_Name'].str.extract(r'(CONC[A-Za-z0-9]+)')
    results['WGS_ID'] = results['WGS_ID_TX'].fillna(results['WGS_ID_CONC'])
    results.drop(columns=['WGS_ID_TX', 'WGS_ID_CONC'], inplace=True)
    print(results)
    out = "/bioinformatics/Candida_auris/mycosnp-nf/output/{}/".format(run_name)
    # Check if demo file exists   
    if my_glob("/bioinformatics/Candida_auris/mycosnp-nf/output/{}/*metadata.xlsx".format(run_name)):
        try:
            demofile = my_glob("/bioinformatics/Candida_auris/mycosnp-nf/output/{}/*metadata.xlsx".format(run_name))[0]
            demo = pd.read_excel(demofile, engine='openpyxl')
            #demo = demo.rename(columns={"WGS_ID": "Sample_Name"})
            #print(demo)
            demo['WGS_ID'] = demo['WGS_ID'].apply(lambda x: x.strip())
            results = pd.merge(results,demo[['WGS_ID','KEY']], on='WGS_ID', how='outer')
        finally:
    #Filter results df and remove controls and failed samples
            results.sort_values(by="Sample_Name", ascending=True, inplace=True, ignore_index=True)
            results=results[results["Sample_Name"].str.contains('SRR*')==False]
            results.to_excel(out + run_name + "_qc_report_and_key.xlsx",  index = False)
    
if __name__ == "__main__":
    prep_qc_report(sys.argv[1]+"_QC_REPORT.txt", sys.argv[1])
