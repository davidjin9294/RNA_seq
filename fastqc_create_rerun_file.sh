#!/bin/bash

# Created by: David Jin (zjin25@g.ucla.edu)

# create file
job_id=$1
concat_path=$2
list_of_failed_path=$3
file=${concat_path}fastqc_rerun_${job_id}.sh

# if everything succeeded, no need to create this script
if [ ! -s "$list_of_failed_path" ]; then
    exit
fi
if test -f ${file} ; then
    rm ${file}
fi
touch ${file}

echo "#!/bin/bash" >> $file 
echo "#$ -cwd" >>$file
echo "#$ -N run_failed_fastqc" >> $file
echo "#$ -l h_data=20G,h_rt=12:00:00" >> $file

#iterate through the list
while IFS= read -r line || [ -n "$line" ]; do
    # Process each line here
    echo "/u/project/arboleda/DATA/software/FastQC/higher_mem_fastqc "$line "--outdir="$4 >> $file
done < $list_of_failed_path




