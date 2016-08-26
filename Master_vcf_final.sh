#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#PBS -S /bin/sh
#PBS -o logs/Master_VCF_final.txt

# Version history
# version 1.4
# 1.2-1.3 - added SGE bash interpreter line to the header
# Version 1.1-1.2 
# Added post processing of SNP matrix to remove lines containing 1 and -1 and combined individual samples and IDs into a single matrix
# Some additional file cleanup 
## V1.4
# added to SGE header

#source variables
source "$SCRIPTPATH"/SPANDx.config
if [ ! ${PBS_O_WORKDIR} ]; then
	PBS_O_WORKDIR="${seq_path}"
fi
cd ${PBS_O_WORKDIR}

log_eval()
{
cd $1
echo -e "\nIn $1\n"
echo "Running: $2"
eval "$2"
status=$?
if [ "${status}" -ne 0 ]; then
	echo "Previous command returned error: ${status}"
	exit 1
else
	echo -e "Completed:\n${2}" >> "${PBS_O_WORKDIR}/logs/Master_vcf_final.cmds"
fi
}

#########################################################################
## checks and creates directory structure
#########################################################################
if [ ! -d "${PBS_O_WORKDIR}/Phylo" ]; then
	mkdir ${PBS_O_WORKDIR}/Phylo
else
	echo -e "Phylo directory already exists \n"
fi
if [ ! -d "${PBS_O_WORKDIR}/Phylo/snps" ]; then
	mkdir ${PBS_O_WORKDIR}/Phylo/snps
else
	echo -e "Phylo/snps directory already exists\n"
fi  
if [ ! -d "${PBS_O_WORKDIR}/Phylo/bams" ]; then
	mkdir ${PBS_O_WORKDIR}/Phylo/bams
else
	echo -e "Phylo/bams directory already exists\n"
fi  
if [ ! -d "${PBS_O_WORKDIR}/Phylo/out" ]; then
	mkdir ${PBS_O_WORKDIR}/Phylo/out
else
	echo -e "Phylo/out directory already exists\n"
fi  
if [ ! -d "${PBS_O_WORKDIR}/Phylo/indels" ]; then
	mkdir ${PBS_O_WORKDIR}/Phylo/indels
else
	echo -e "Phylo/indels directory already exists\n"
fi
if [ "$(ls -A ${PBS_O_WORKDIR}/Phylo/snps)" ]; then
	echo "snps directory contains files"
else
	echo "snps directory is not empty. Please make sure your SNP.vcf files have been copied or linked into this directory"
	exit 1	
fi
if [ "$(ls -A ${PBS_O_WORKDIR}/Phylo/bams)" ]; then
	echo "bams directory contains files"
else
	echo "snps directory is not empty. Please make sure your SNP.vcf files have been copied or linked into this directory"
	exit 1
fi

#########################################################################
#Checks for the master vcf file and creates it
#########################################################################
if [ ! -s "${PBS_O_WORKDIR}/Phylo/out/master.vcf" ]; then
	array=($(find ${PBS_O_WORKDIR}/Phylo/snps/*.vcf -printf "%f "))
	array2=("${array[@]/.vcf/,VCF}")
	array3=("${array2[@]/#/-V:}")
	n=${#array3[@]}
	for (( i=0; i<n; i++ )); do 
		input[i]=${array3[i]}" "${array[i]};
	done;
	log_eval ${PBS_O_WORKDIR}/Phylo/snps "${JAVA} ${SET_VAR} -Djava.io.tmpdir=${seq_directory}/tmp ${GATK} -T CombineVariants -R ${PBS_O_WORKDIR}/${ref}.fasta ${input[*]} --sites_only -o ${PBS_O_WORKDIR}/Phylo/out/master.vcf"
else
	echo -e "The merged snp calls have already been combined into the master.vcf file\n"
fi
sleep 20
exit 0
