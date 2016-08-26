#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#PBS -S /bin/sh
#PBS -o logs/BedCov_merge.txt

# v1.3
# Version history
#
# 1.2-1.3 - added SGE bash interpreter line to the header

if [ -z "${PBS_O_WORKDIR}" ]; then
	PBS_O_WORKDIR="${seq_path}"
fi
cd "${PBS_O_WORKDIR}"

log_eval()
{
cd $1
echo -e "\nIn $1\n"
echo "Running: ${@:2}"
eval "${@:2}"
status=$?
if [ "${status}" -ne 0 ]; then
	echo "Previous command returned error: ${status}"
	exit 1
else
	echo -e "Completed:\n${@:2}" >> "${PBS_O_WORKDIR}/logs/BedCov_merge.cmds"
fi
}

if [ ! -s "${PBS_O_WORKDIR}/Outputs/Comparative/Bedcov_merge.txt" ]; then
	unset ${array}
	unset ${array2}
	array=($(find ${PBS_O_WORKDIR}/BEDcov/*.bedcov -printf "%f "))
	array2=("${array[@]/.bedcov/}")
	array3=("${array[@]/.bedcov/.cut}")
	n=${#array2[@]}
	for (( i=0; i<n; i++ )); do
		if [ ! -s ${PBS_O_WORKDIR}/BEDcov/${array2[i]}.sort ]; then
			cat ${PBS_O_WORKDIR}/BEDcov/${array2[i]}.bedcov | sort -k1,1 -k2,2n > ${PBS_O_WORKDIR}/BEDcov/${array2[i]}.sort
		fi 
		if [ ! -s ${PBS_O_WORKDIR}/BEDcov/${array2[i]}.cut ]; then
			cat ${PBS_O_WORKDIR}/BEDcov/${array2[i]}.sort | cut -f 7 > ${PBS_O_WORKDIR}/BEDcov/${array2[i]}.cut
			sed -i '1s/^/'${array2[i]}'\n/' ${PBS_O_WORKDIR}/BEDcov/${array2[i]}.cut
		fi
	done
	if [ ! -s "${PBS_O_WORKDIR}/BEDcov/head.bed" ]; then
		cat ${PBS_O_WORKDIR}/BEDcov/${array2[1]}.sort | cut -f 1-3 > ${PBS_O_WORKDIR}/BEDcov/head.bed
		sed -i '1s/^/\t\t\n/' ${PBS_O_WORKDIR}/BEDcov/head.bed
	fi

## create merged columns
	if [ ! -s "${PBS_O_WORKDIR}/Outputs/Comparative/Bedcov_merge.txt" ]; then
		log_eval "${PBS_O_WORKDIR}/BEDcov" "paste head.bed ${array3[*]} > ${PBS_O_WORKDIR}/Outputs/Comparative/Bedcov_merge.txt"
		rm ${PBS_O_WORKDIR}/BEDcov/*.cut ${PBS_O_WORKDIR}/BEDcov/*.sort ${PBS_O_WORKDIR}/BEDcov/head.bed
	fi
fi
sleep 20
exit 0
