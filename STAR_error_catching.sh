#!/bin/bash

# Created by: David Jin (zjin25@g.ucla.edu)

# variables needed:
star_file_path=$1 #$experiment_concat_STAR_path
current_dir=$2  #$job_message_path: need / at the end
job_number=$3   #$jobID
concat_path=$4  #$experiment_concat_path
concat_r1_path=$5 #$experiment_concat_r1_path
concat_r2_path=$6 #$experiment_concat_r2_path



# find input list of pathways
sample_pathway_list=${concat_path}sample_pathway_list.txt
input_paths=$(while read -r line; do basename "$line"; done < $sample_pathway_list)
# extract job number
qacct_output=$(/u/systems/UGE8.6.4/bin/lx-amd64/qacct -j $job_number)
# save it
#echo "$qacct_output" > ${concat_path}STAR_qacct.txt
# extract the taskids
ids=$(echo "$qacct_output" | grep ^taskid)
# extract the errors
errors=$(echo "$qacct_output" | grep ^failed)
# combine taskids with errors
combined_output=$(echo "$ids" | paste -d ' ' - <(echo "$errors"))
# delete STAR_failed_index if it already exists
if test -f ${concat_path}STAR_failed_index_${job_number}.txt ; then                                                                 
    rm ${concat_path}STAR_failed_index_${job_number}.txt 
fi
if test -f ${concat_path}STAR_failed_messages_${job_number}.txt; then
    rm ${concat_path}STAR_failed_messages_${job_number}.txt
fi
#echo $combined_output >> ${concat_path}error_output_${job_number}.txt
# check if each task finishes
for file in $current_dir*.e"$job_number"*; do
    echo -e "========================="
    # get taskid
    task_id=$(echo "$file" | awk -F '.' '{print $NF}')
    # print taskid
    echo "task id:" $task_id
    path=$(sed -n "${task_id}p" $sample_pathway_list)
    job=$(basename $path)
    error_code=$(grep -E "^taskid\s+$task_id" <<<"$combined_output" | awk '{print $4}')
    error_message=$(grep -E "^taskid\s+$task_id" <<<"$combined_output" | awk '{for(i=6;i<=NF;i++) printf "%s ", $i; print""}')
    # check Log.final.out
    if [ -e "${star_file_path}${job}_Log.final.out" ]; then
	echo ${job}_Log.final.out "found"
    else 
	# if failed, need to figure out why it failed
       	if [ -z "$error_message" ]; then
       	    echo ${job}_Log.final.out "not found: encountered unknown error with exit code" $error_code
       	else
       	    echo ${job}_Log.final.out "not found: due to" $error_message
       	fi
	failed_index=$(grep -n ${job} ${sample_pathway_list} | cut -f1 -d:)
	echo $failed_index >> ${concat_path}STAR_failed_index_${job_number}_temp.txt
    fi

    # check out.tab
    if [ -e "${star_file_path}${job}_SJ.out.tab" ]; then
	echo ${job}_SJ.out.tab "found"
    else
       	if [ -z "$error_message" ]; then
       	    echo ${job}_SJ.out.tab "not found: encountered unknown error with exit code" $error_code
       	else
       	    echo ${job}_SJ.out.tab "not found: due to" $error_message
       	fi
	failed_index=$(grep -n ${job} ${sample_pathway_list} | cut -f1 -d:) 
	echo $failed_index >> ${concat_path}STAR_failed_index_${job_number}_temp.txt
    fi


done >> ${concat_path}STAR_failed_messages_${job_number}.txt
#chmod a+w ${concat_path}STAR_failed_index_${job_number}.txt
sort ${concat_path}STAR_failed_index_${job_number}_temp.txt | uniq > ${concat_path}STAR_failed_index_${job_number}.txt
rm ${concat_path}STAR_failed_index_${job_number}_temp.txt







