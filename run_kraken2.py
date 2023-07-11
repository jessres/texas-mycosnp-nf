import subprocess
#export KRAKEN2_DB_PATH="/home/jessr/kraken2_db/:/jessr/kraken2_db/"

# removing the new line characters
with open('kraken2.txt') as f:
  lines = [line.rstrip() for line in f]
 
print(lines)

# prepare run commands with sample names for Kraken 2 
for sample_name in lines:
  print ("Generating Kraken2 command for: " + sample_name)
  kraken2 = "/home/jessr/kraken2/kraken2 --db /home/jessr/kraken2/kraken2_db --gzip-compressed --output /home/jessr/mycosnp-nf/output/kraken2_output.txt --report /home/jessr/mycosnp-nf/output --report-minimizer-data --use-mpa-style " + sample_name
  print ("The command used was: " + kraken2)
  subprocess.call(kraken2, shell=True)
done
