
#!/bin/bash

# Created by: Angela Wei, David Jin (zjin25@g.ucla.edu)

echo $'\n'
#making aboslute pathways again; pass experiment name with "/" at the end
# Make sure it starts with a slash
while true; do
    echo "What experiment directory inside /u/project/arboleda/DATA/RNAseq/ are you analyzing? Make sure it ends with a slash, /"
    read experiment_dir
    if [[ $experiment_dir == */ ]]; then
	break
    else
	echo $'\n'
	echo "The directory name must end with a slash (/). Please try again."
    fi
done
experiment_name="$(basename -- $experiment_dir)"

#change to /u/project/arboleda/DATA/RNAseq when needed
#these lines generate the absolute pathways for the concatenated reads again
rnaseq_directory="/u/project/arboleda/DATA/RNAseq/"
concat="_concat/"
concat_r1="_concat_r1/"
concat_r2="_concat_r2/"

experiment_concat_path="$rnaseq_directory$experiment_name$concat"
experiment_concat_r1_path="$experiment_concat_path$experiment_name$concat_r1"
experiment_concat_r2_path="$experiment_concat_path$experiment_name$concat_r2"

concat_STARmapped="_concat_STARmapped/"
experiment_concat_STARmapped="$experiment_concat_path$experiment_name$concat_STARmapped"

experiment_path=${rnaseq_directory}${experiment_dir}

# Check if the directory already exists.                                                                                                                      
if [ -d "$experiment_concat_STARmapped" ]; then
    echo "Error: The directory $experiment_concat_STARmapped already exists. Exiting."
    exit
fi
#make a directory to hold mapped reads
mkdir $experiment_concat_STARmapped

#give group write permissions to this directory
chmod g+w $experiment_concat_STARmapped

echo "Experiment concat path" $experiment_concat_path
echo "Experiment concat r1 path" $experiment_concat_r1_path
echo "Experiment concat r2 path" $experiment_concat_r2_path
echo "Experiment concat STAR mapped path" $experiment_concat_STARmapped

#each line in sample_name_list.txt is a sample name
#total line count is then the total number of samples
total_sample_number=$( wc -l <  ${experiment_concat_path}sample_pathway_list.txt)

#path where the user's wrapper mapping script is stored
user_rnaseq_submit_path="/u/project/arboleda/DATA/Scripts/User-RNAseq/User-RNAseq-STAR-mapping/"

#absolute path where the actual mapping script is called
STARmapping_array_script_path="/u/project/arboleda/angelawe/RNAseq_Scripts/STAR_mapping_scripts/STAR_mapping_array.sh"

#warning
echo $'\n'
echo "DO NOT ENTER ANSWERS WITH SPACES, use dashes or underscores instead of spaces"
echo "If you submit a faulty answer, press <Control> and <C> at the same time to stop running this script!"
echo $'\n'

#take in user information
echo "What is your name? Type your name following the format FirstName-LastName and press enter"
read user_name
echo $'\n'

while true; do
    echo "What is the absolute path where you would like to put the job error and output messages? Make sure it ends with a slash, aka '/'"
    read job_message_path
    if [[ $job_message_path == */ ]]; then
        break
    else
        echo $'\n'
        echo "The path must end with a slash ('/'). Please try again."
    fi
done

echo "Would you like email notifications for when each sample concatenation begins? Answer YES or NO"
read m_param_decision
echo $'\n'

echo "What overhang length are you using? (This number is the max readlength minus 1) "
read overhang_number
echo $'\n'

#absolute pathway of the scipt that will be generated
#this script name will be in the format "FirtName-LastNameDate_submit_concat_array.sh"
string_submit="_submit_STARmapping_array.sh"
current_date=$(date +%Y-%m-%d)
user_STARmapping_script="${user_rnaseq_submit_path}${user_name}_${experiment_name}_${current_date}${string_submit}"

#check if the file already exists. If so, ask the user if they want to overwrite.
if test -f ${user_STARmapping_script} ; then
    echo "File ${user_STARmapping_script} already exists. Do you want to overwite its current content? Answer YES or NO"
    read overwrite
    if [ "${overwrite}" == "YES" ]; then
	echo "Overwriting the original file: ${user_STARmapping_script}" 
	rm ${user_STARmapping_script}
    else
	while true; do
	    echo "Specify the file name of your choice to store in /u/project/arboleda/DATA/Scripts/User-${task}/User-${task}-STAR-mapping/"
	    echo "Make sure it ends with '.sh' so it is a shell script. It is recommended to include your name. For example, Bruin_script_v2.sh"
	    echo "If you change your mind and want to overwrite the original file, type OVERWRITE."
	    read file_name

            if [[ $file_name == "OVERWRITE" ]]; then
                rm "${user_STARmapping_script}"
                echo "Overwriting the original file: ${user_STARmapping_script}"
                break
	    elif [[ $file_name == *.sh ]]; then
		user_STARmapping_script="${user_rnaseq_submit_path}${file_name}"
		# Make sure this customized name does not exist
                if test -f "${user_STARmapping_script}" ; then
                    echo "File ${user_STARmapping_script} already exists. Please choose a different name."
                else
                    echo "File ${user_STARmapping_script} created."
                    break
                fi
	    else
		echo $'\n'
		echo "The file name must end with '.sh'. Please try again."
	    fi
	done
    fi
fi


#now write the user's personalized wrapper script
echo '#!/bin/bash' >> ${user_STARmapping_script}
echo '#$ -l h_data=32G,h_rt=7:00:00,highp' >> ${user_STARmapping_script}
echo '#$ -pe shared 2'>> ${user_STARmapping_script}
echo '#$ -e '${job_message_path} >> ${user_STARmapping_script}
echo '#$ -o '${job_message_path} >> ${user_STARmapping_script}
echo '#$ -t 1-'${total_sample_number}':1' >> ${user_STARmapping_script}
if [ "${m_param_decision}" = "YES" ]
        then echo '#$ -m bea' >> ${user_STARmapping_script}
fi
echo "" >> ${user_STARmapping_script}
echo 'i=$((SGE_TASK_ID))' >> ${user_STARmapping_script}
echo ${STARmapping_array_script_path}' $i '${experiment_concat_path} ${experiment_concat_r1_path} ${experiment_concat_r2_path} ${experiment_concat_STARmapped} ${overhang_number} ${experiment_path} >> ${user_STARmapping_script}

#default the new script will have these permissions: -rw-r--r--
chmod u+x,g+x,g+w ${user_STARmapping_script}

echo ${user_STARmapping_script}" has been generated"

#now submit the job to be run
STARmapping="_STARmapping_"
STARmapping_job_name=${user_name}${STARmapping}${current_date}
echo "This is the job name "${STARmapping_job_name}
job_message=`qsub -N ${STARmapping_job_name} ${user_STARmapping_script}`
echo $job_message
jobID=`echo $job_message | awk 'match($0,/[0-9]+/){print substr($0, RSTART, RLENGTH)}'` 

# error catching
qsub -hold_jid ${STARmapping_job_name} -o ${job_message_path} -e ${job_message_path} -N STAR_error_checking_${jobID} /u/home/z/zjin25/Scripts/RNA_seq_scripts/STAR_error_catching.sh ${experiment_concat_STARmapped} ${job_message_path} ${jobID} ${experiment_concat_path} ${experiment_concat_r1_path} ${experiment_concat_r2_path}

qsub -hold_jid ${STARmapping_job_name},STAR_error_checking_${jobID} -o ${job_message_path} -e ${job_message_path} -N STAR_create_rerun_script /u/home/z/zjin25/Scripts/RNA_seq_scripts/STAR_create_rerun_file.sh ${jobID} ${experiment_concat_path} ${experiment_concat_path}STAR_failed_index_${jobID}.txt ${job_message_path} ${experiment_concat_r1_path} ${experiment_concat_r2_path} ${experiment_concat_STARmapped} ${overhang_number} ${experiment_path}
# create rerun file

