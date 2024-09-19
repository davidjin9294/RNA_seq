#!/bin/bash

# Created by: Angela Wei, David Jin (zjin25@g.ucla.edu)



echo $'\n'

# Ask the user if they are doing RNAseq or ATACseq. 
while true; do
    echo "Are you performing RNAseq or ATACseq? Answer RNAseq or ATACseq."
    read task

    if [[ $task == "RNAseq" || $task == "ATACseq" ]]; then
	# only break on these two input. Loop otherwise.
        break
    else
	echo $'\n'
        echo "Must be either RNAseq or ATACseq. Please try again."
    fi
done

#path where the user's script is stored
user_concat_path="/u/project/arboleda/DATA/Scripts/User-"${task}"/User-"${task}"-Concatenation/"

#absolute path to the concatenation script
concat_array_script_path="/u/project/arboleda/angelawe/RNAseq_Scripts/concatenation_scripts/concat_array.sh"

#make the directories for output
#this is where all RNAseq/ATACseq data is stored
directory="/u/project/arboleda/DATA/"${task}"/"

echo $'\n'
#ask for the experiment directory user is concatenating
while true; do
    echo "What is the directory inside /u/project/arboleda/DATA/${task}/ you are concatenating? Make sure the name is spelled exactly the same and ends with a slash, aka /"
    read experiment_dir

    if [[ $experiment_dir == */ ]]; then
        break
    else
	echo $'\n'
        echo "The directory name must end with a slash (/). Please try again."
    fi
done
 
experiment_path="$directory$experiment_dir"
echo "Experiment path: " $experiment_path

echo "Making pathways concatenated reads will go in"
concat="_concat/"
concat_r1="_concat_r1/"
concat_r2="_concat_r2/"
concat_qc="_concat_qc/"

#cannot use user input for experiment name because it has a "/" at the end of it; i just want the string so we can name new dir with it
experiment_name="$(basename -- $experiment_path)"
echo "Experiment name: " $experiment_name

experiment_concat_path="$directory$experiment_name$concat"
experiment_concat_r1_path="$experiment_concat_path$experiment_name$concat_r1"
experiment_concat_r2_path="$experiment_concat_path$experiment_name$concat_r2"
experiment_concat_qc_path="$experiment_concat_path$experiment_name$concat_qc"

echo "Directory containing concatenated info: " $experiment_concat_path
echo "Directory containing concatenated r1 reads: " $experiment_concat_r1_path
echo "Directory containing concatenated r2 reads: " $experiment_concat_r2_path
echo "Directory containing qc for concatenation: " $experiment_concat_qc_path

# Check if the directory already exists.
if [ -d "$experiment_concat_path" ]; then
    echo "Error: The directory $experiment_concat_path already exists. Exiting."
    exit
fi


echo "Making directories for concatenated reads"
mkdir $experiment_concat_path
mkdir $experiment_concat_r1_path
mkdir $experiment_concat_r2_path
mkdir $experiment_concat_qc_path

#add group writing permissions to new directories
chmod g+w $experiment_concat_path
chmod g+w $experiment_concat_r1_path
chmod g+w $experiment_concat_r2_path
chmod g+w $experiment_concat_qc_path

echo "Writing all the sample pathways into a .txt"
for dir in $experiment_path*/
do
echo ${dir%} >> ${experiment_concat_path}sample_pathway_list.txt
done

total_sample_number=$( wc -l <  ${experiment_concat_path}sample_pathway_list.txt )

echo "Total sample number: "$total_sample_number

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

#absolute pathway of the scipt that will be generated
#this script name will be in the format "FirtName-LastNameDate_submit_concat_array.sh"
string_submit="_submit_concat_array.sh"
current_date=$(date +%Y-%m-%d)
user_concat_script="${user_concat_path}${user_name}_${experiment_name}_${current_date}${string_submit}"


#check if the file already exists. If so, ask the user if they want to overwrite.
if test -f ${user_concat_script} ; then
    echo "File ${user_concat_script} already exists. Do you want to overwite its current content? Answer YES or NO"
    read overwrite
    if [ "${overwrite}" == "YES" ]; then
	echo "Overwriting the original file: ${user_concat_script}" 
	rm ${user_concat_script}
    else
	while true; do
	    echo "Specify the file name of your choice to store in /u/project/arboleda/DATA/Scripts/User-${task}/User-${task}-Concatenation/"
	    echo "Make sure it ends with '.sh' so it is a shell script. For example, Script_v2.sh"
	    echo "If you change your mind and want to overwrite the original file, type OVERWRITE."
	    read file_name

            if [[ $file_name == "OVERWRITE" ]]; then
                rm "${user_concat_script}"
                echo "Overwriting the original file: ${user_concat_script}"
                break
	    elif [[ $file_name == *.sh ]]; then
		user_concat_script="${user_concat_path}${file_name}"
		# Make sure this customized name does not exist
                if test -f "${user_concat_script}" ; then
                    echo "File ${user_concat_script} already exists. Please choose a different name."
                else
                    echo "File ${user_concat_script} created."
                    break
                fi
	    else
		echo $'\n'
		echo "The file name must end with '.sh'. Please try again."
	    fi
	done
    fi
fi
#now write the script
echo '#!/bin/bash' >> ${user_concat_script}
echo '#$ -l h_data=16G,h_rt=4:00:00' >> ${user_concat_script}
echo '#$ -e '${job_message_path} >> ${user_concat_script}
echo '#$ -o '${job_message_path} >> ${user_concat_script}
echo '#$ -t 1-'${total_sample_number}':1' >> ${user_concat_script}
if [ "${m_param_decision}" = "YES" ]
        then echo '#$ -m bea' >> ${user_concat_script}
fi
echo "" >> ${user_concat_script}
echo 'i=$((SGE_TASK_ID))' >> ${user_concat_script}
echo ${concat_array_script_path}' $i '${experiment_path} ${experiment_concat_path} ${experiment_concat_r1_path} ${experiment_concat_r2_path} ${experiment_concat_qc_path} >> ${user_concat_script}

#default the new script will have these permissions: -rw-r--r--
chmod u+x,g+x,g+w ${user_concat_script}

echo ${user_concat_script}" has been generated"

#now submit the job to be run
concat="_concat_"
concat_job_name=${user_name}${concat}${current_date}
job_message=`qsub -N ${concat_job_name} ${user_concat_script}`
echo $job_message
jobID=`echo $job_message | awk 'match($0,/[0-9]+/){print substr($0, RSTART, RLENGTH)}'`
#wait for the previous job to finish and start error checking
qsub -hold_jid ${concat_job_name} -o ${job_message_path} -e ${job_message_path} -N error_checking_${jobID} /u/home/z/zjin25/Scripts/RNA_seq_scripts/fastqc_error_catching.sh ${experiment_concat_qc_path} ${job_message_path} ${jobID} ${experiment_concat_path} ${experiment_concat_r1_path} ${experiment_concat_r2_path}
#wait for the above two to finish and write this script
qsub -hold_jid ${concat_job_name},error_checking_${jobID} -o ${job_message_path} -e ${job_message_path} -N create_rerun_script /u/home/z/zjin25/Scripts/RNA_seq_scripts/fastqc_create_rerun_file.sh ${jobID} ${experiment_concat_path} ${experiment_concat_path}fastqc_failed_index_${jobID}.txt ${experiment_concat_qc_path}


