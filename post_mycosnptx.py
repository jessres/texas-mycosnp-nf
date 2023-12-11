#!/usr/bin/env python3
version="post mycosnptx version 1.0"
#author		 :Jessica Respress
#date		 :20231129
#usage		 :bash post_mycosnptx.py <run_name>

from fnmatch import fnmatch
import glob
import pandas as pd
from glob import glob as my_glob
from os import path
from datetime import datetime,date
import sys
import shutil
import os
import pandas

def prep_SRA_submission(results, run_name):
    reads_dir = "/home/dnalab/Candida_auris/mycosnp-nf/reads/{}/".format(run_name)
    metadata = pd.read_csv("/home/dnalab/Candida_auris/templates/NCBI_SRA_metadata_template.csv", header=0, index_col=None)
    attribute = pd.read_csv("/home/dnalab/Candida_auris/templates/NCBI_biosample_attributes_template.csv", header=0, index_col=None)
    results = pd.read_csv("/home/dnalab/Candida_auris/mycosnp-nf/output/{}/{}".format(run_name,results), sep="\t", header=0, index_col=False, dtype=str)
    results.rename(columns=lambda x: x.strip(), inplace=True)
    results['Sample_Name'] = results['Sample_Name'].apply(lambda x: x.strip())
    results['WGS_ID_TX'] = results['Sample_Name'].str.extract(r'(TX-DSHS-CAU-\d+)')
    results['WGS_ID_CONC'] = results['Sample_Name'].str.extract(r'(CONC[A-Za-z0-9]+)')
    results['WGS_ID'] = results['WGS_ID_TX'].fillna(results['WGS_ID_CONC'])
    results.drop(columns=['WGS_ID_TX', 'WGS_ID_CONC'], inplace=True)    
    out = "/home/dnalab/Candida_auris/mycosnp-nf/output/{}/".format(run_name)
    SRA_fastq = "/home/dnalab/Candida_auris/mycosnp-nf/output/{}/SRA_fastq/".format(run_name)
    # Check if demo file exists
    
    if my_glob("/home/dnalab/Candida_auris/mycosnp-nf/output/{}/*metadata.xlsx".format(run_name)):
        try:
            demofile = my_glob("/home/dnalab/Candida_auris/mycosnp-nf/output/{}/*metadata.xlsx".format(run_name))[0]
            demo = pd.read_excel(demofile, engine='openpyxl')
            #demo = demo.rename(columns={"WGS_ID": "Sample_Name"})
            demo.rename(columns=lambda x: x.strip(), inplace=True)            
            results = pd.merge(results, demo, left_on = "WGS_ID", right_on = "WGS_ID", how = "outer")
            results.fillna('missing', inplace=True)
            #print(demo)
        finally:
    #Filter results df and remove controls and failed samples
          results.sort_values(by="Sample_Name", ascending=True, inplace=True, ignore_index=True)
          results=results[results['Pass/Fail'].str.contains('PASS')]
          results=results[results['Sample_Name'].str.contains('CON')==False]
          results=results[results['Sample_Name'].str.contains('SRR')==False]
          print("Files to be submitted:")
    #print(results)
          print(results[['Sample_Name']].to_string(index=False))
    
          if "_" in (run_name):
            instrument = run_name.split("_")[2]
          elif "-" in (run_name):
            instrument = run_name.split("-")[1]
    #print(instrument)
#Extract instrument name from sample name     
          if instrument[0] == "M":
            instrument_name = "Illumina MiSeq"
          elif instrument[0] == "V":
            instrument_name = "Illumina NovaSeq2000"
          print("Instrument:")
          print(instrument_name)
# Rename columns in dataframe and add columns for each sample fastq path and instrument name    
          results = results.rename({"Sample_Name":"sample_id","SourceSite":"sourceSite","Submitter":"submitter","IsolatDate":"collection_date"}, axis='columns')
          results['path'] = results['sample_id'].apply(lambda sample_id: reads_dir + sample_id)
          path_list = results['path'].tolist()
          results['instrument_model'] = results['sample_id'].apply(lambda sammple_id: instrument_name)
          results=results.reset_index(drop=True)
          results['path'] = results['path'].apply(lambda x: x.strip())
          
# Normalize date and remove time
          collection_dates = []
          dates = results['collection_date']
          for date in dates:
            if date == "missing":
              YMD = "missing"
              collection_dates.append(YMD) 
            elif date != "missing":
              YMD = date.strftime("%Y-%m-%d")
              collection_dates.append(YMD)
              collection_date = pd.DataFrame(collection_dates, columns=['collection_dates'])
            #print(YMD)
#Collect fastq path          
          fastq_files = []
          for fastq in path_list:
            if path.exists(reads_dir):
              items = glob.glob(fastq + '*.fastq.gz')
              fastq_files.extend(items)
              #results = results.append(fastq_files)
              #print(results)
            else:
              print(f"fastq files do not exist at path: {reads_dir}")
              
#Copy files for submission to the SRA_fastq directory         
          for fastq_file in fastq_files:
            if path.exists(SRA_fastq):
              shutil.copy (fastq_file, SRA_fastq)
              print(f"{fastq_file} copied to submission directory")
            else:
              os.mkdir(SRA_fastq)
              shutil.copy (fastq_file, SRA_fastq)
              print(f"{fastq_file} copied to submission directory")

          SRA_files_R1 = []
          SRA_files_R2 = []
          for files in glob.glob(SRA_fastq + '*R1_001.fastq.gz'):
            SRA_files_R1.append(files)
            #print(SRA_files_R1)
          for files in glob.glob(SRA_fastq + '*R2_001.fastq.gz'):
            SRA_files_R2.append(files)
          SRA_file_path_R1 = pd.DataFrame(SRA_files_R1, columns=['R1'])
          SRA_file_path_R1.sort_values(by="R1", ascending=True, inplace=True, ignore_index=True)
          SRA_file_path_R2 = pd.DataFrame(SRA_files_R2, columns=['R2'])
          SRA_file_path_R2.sort_values(by="R2", ascending=True, inplace=True, ignore_index=True)
          #print(SRA_file_path)  
          

#Fill in SRA_metadata template with samples to be submitted
          new_row_metadata = {"sample_id": results["sample_id"],"library_ID": results["sample_id"],"title": "CDC Mycotic Diseases Branch Candida auris pathogen surveillance","library_strategy": "WGS","library_source": "GENOMIC","library_selection": "RANDOM","library_layout": "RANDOM","platform": "ILLUMINA","instrument model": results["instrument_model"],"design_description": "Illumina DNA Prep","filetype": "fastq","filename": SRA_file_path_R1["R1"],"filename2": SRA_file_path_R2["R2"],"filename3": "","filename4": "","assembly": "","fasta_file": ""}
          new_row_metadata = pd.DataFrame(new_row_metadata)         
          metadata = metadata.append(new_row_metadata, ignore_index = True)
          metadata.to_csv(out + run_name + "_SRA_metadata.csv",  index = False)
          
#Fill in SRA_attribute template with samples to be submitted
          new_row_attr = {"sample_name": results["sample_id"], "bioproject_accession": "PRJNA642852", "organism": "Candida auris", "collection_date": collection_date["collection_dates"], "geo_loc_name": "USA:Mountain", "host":"Homo sapiens", "host_disease":"not collected", "isolate": results["sample_id"], "isolation_source": results["sourceSite"], "latitude_and_longitude": "Not_collected"}
          new_row_attr = pd.DataFrame(new_row_attr)                      
          attribute = attribute.append(new_row_attr, ignore_index = True)
          attribute.to_csv(out + run_name + "_SRA_attribute.tsv", sep = "\t", index = False)    
    
          return results
  

if __name__ == "__main__":
    prep_SRA_submission(sys.argv[1]+"_QC_REPORT.txt", sys.argv[1])
