#!/bin/bash

# Created by: David Jin (zjin25@g.ucla.edu)
# input
job_id=$1
concat_path=$2
list_of_failed_path=$3
error_path=$4
output_path=$4
r1_path=$5
r2_path=$6
star_path=$7
length=$8
data_path=$9
# output file
file=${concat_path}STAR_rerun_${job_id}.sh
if test -f ${file}; then
    rm ${file}
fi

if [ ! -s "$list_of_failed_path" ]; then
    exit
fi   

touch ${file}
echo "${file} created"

# writing the file
echo "#!/bin/bash" >> $file
echo "#$ -l h_data=60G,h_rt=100:00:00,highp" >> $file
echo "#$ -N rerun_failed_alignment_jobs" >> $file
echo "#$ -pe shared 2" >> $file
echo "#$ -e ${error_path}" >> $file
echo "#$ -o ${output_path}" >> $file

num_of_samples=$(wc -l < ${list_of_failed_path})

echo "#$ -t 1-${num_of_samples}:1" >> $file


echo "i=\$((SGE_TASK_ID))" >> $file

## USE THIS CODE IF YOU HAVE A LIST OF FAILED INDICES

echo "to_rerun=\$(sed -n \${i}p $list_of_failed_path)" >> $file


echo "/u/project/arboleda/angelawe/RNAseq_Scripts/STAR_mapping_scripts/STAR_mapping_array.sh \$to_rerun ${concat_path} ${r1_path} ${r2_path} ${star_path} ${length} ${data_path}" >> $file

