
#install java
#download from linuxX64 from https://www.java.com/en/download/linux_manual.jsp
#save the tar file to where you want it installed

# cd /work/software/java/
#
# #Unpack the tarball and install Java
# tar -zxvf jre-8u73-linux-x64.tar.gz

sudo apt install default-jre

#install nextflow
cd /home/cosnp

curl -s https://get.nextflow.io | bash
chmod +x nextflow
nextflow self-update
# or
wget -qO- https://get.nextflow.io | bash
chmod +x nextflow
nextflow self-update
