#!/bin/bash

# Created by: David Jin (zjin25@g.ucla.edu)

# variables needed:
qc_file_path=$1 #$experiment_concat_qc_path
current_dir=$2  #$job_message_path: need / at the end
job_number=$3   #$jobID
concat_path=$4  #$experiment_concat_path
concat_r1_path=$5 #$experiment_concat_r1_path
concat_r2_path=$6 #$experiment_concat_r2_path


# get the path to the experiment_dir
# find all files output
output_qc_files=$(ls $qc_file_path | grep zip)
# find input list of pathways
sample_pathway_list=${concat_path}sample_pathway_list.txt
input_paths=$(while read -r line; do basename "$line"; done < $sample_pathway_list)
# extract job number
qacct_output=$(/u/systems/UGE8.6.4/bin/lx-amd64/qacct -j $job_number)
# extract the taskids
ids=$(echo "$qacct_output" | grep ^taskid)
# extract the errors
errors=$(echo "$qacct_output" | grep ^failed)
# combine taskids with errors
combined_output=$(echo "$ids" | paste -d ' ' - <(echo "$errors"))
# delete rerun_list if it already exists
if test -f ${concat_path}fastqc_failed_index_${job_number}.txt ; then                                                                 
    rm ${concat_path}fastqc_failed_index_${job_number}.txt 
fi
if test -f ${concat_path}fastqc_failed_messages_${job_number}.txt; then
    rm ${concat_path}fastqc_failed_messages_${job_number}.txt
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
    # check *r1
    if grep -q ${job}_r1 <<< $output_qc_files; then
	echo ${job}_r1 "succeeded"
    else 
	# if failed, need to figure out why it failed
	# check if it started
	if grep -q ^Started.*${job}_r1 $file; then
	    # check if finished
	    if ! grep -q .*95.*${job}_r1 $file; then
		if [ -z "$error_message" ]; then
		    echo ${job}_r1 "failed: encountered unknown error with exit code" $error_code
		else
      		    echo ${job}_r1 "failed: started but did not finish due to" $error_message
		fi
	    fi
	# if it did not even start
	else 
	    echo ${job}_r1 "failed: did not start"
	fi
	#create a file with all the paths to r1 that needs to be reran
	echo $concat_r1_path${job}_r1.fastq.gz >> ${concat_path}fastqc_failed_index_${job_number}.txt
    fi

    # check *r2
    if grep -q ${job}_r2 <<< $output_qc_files; then
	echo ${job}_r2 "succeeded"
    else
	if grep -q ^Started.*${job}_r2 $file; then
	    if ! grep -q .*95.*${job}_r2 $file; then
		if [ -z "$error_message" ]; then
		    echo ${job}_r2 "failed: encountered unknown error with exit code" $error_code
		else
		    echo ${job}_r2 "failed: started but did not finish due to" $error_message
		fi
	    fi
	else 
	    echo ${job}_r2 "failed: did not start. Potentially due to previous error in *r1"
        fi
	echo $concat_r2_path${job}_r2.fastq.gz >> ${concat_path}fastqc_failed_index_${job_number}.txt
    fi


done >> ${concat_path}fastqc_failed_messages_${job_number}.txt









