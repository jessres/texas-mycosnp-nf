#!/bin/python

version="kraken2_CA version 1.0"
#author		 :Jessica Respress
#date		 :20230627
#usage		 :python kraken2_CA.py > output.txt

import glob
import sys

#Example file strucutre and sample read location
#/home/jessr/mycosnp-nf/output/CA_230519_M06018/samples/AME2300060-TX-M06018-230519_S17/faqcs/AME2300060-TX-M06018-230519_S17.trimmed.unpaired.fastq.gz

#run = sys.argv[1]
print(glob.glob("samples/*/faqcs/*.trimmed.unpaired.fastq.gz")) 
done
