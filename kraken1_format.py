import os
import subprocess

f = os.listdir("/bioinformatics/AMD/Candida_auris/mycosnp-nf/output/kraken2_output")
kraken_report = [line.rstrip() for line in f]
print(kraken_report) 

for file_name in kraken_report:
  kraken1_format =  "cut -f1-3,6-8 /bioinformatics/AMD/Candida_auris//mycosnp-nf/output/kraken2_output/" + file_name + " > /bioinformatics/AMD/Candida_auris/mycosnp-nf/output/kraken1_format/" + file_name
  subprocess.call(kraken1_format, shell=True)
