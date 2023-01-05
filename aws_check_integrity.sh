#!/bin/bash
#echo "First arg: $1 <local_path>"
#echo "Second arg: $2 <bucket_name>"
#echo "Third arg: $3 <bucket_folder>"

#########################
## Prerrequisites
########################

# 1. The user must be already connected to S3
# 2. The local directory must be sincronised with AWS by using the "sync" command


#########################
## Receive parameters
#########################

if [ $# -ne  4 ]; then
	printf "\n"
	echo "ERROR: Please pass arguments."
	printf "Usage :\n aws_check_integrity.sh <local_path> <bucket_name> <bucket_folder>\n\t- local_path: local path where all files, previously uploaded on AWS, are currently stored. For example: /data/nucCyt/raw_data/.\n\t- bucket_name: the name of the S3 bucket we want to check. For example: nuccyt.\n\t- bucket_folder: the name of the root folder on the S3 bucket. For example raw_data. In case there is not any folder in the root, this parameter will be a slash (/) indicating the root path. Example, raw_data/.\n\n"
	exit 128
elif [ ! -d "$1" ]; then
	printf "\n"
	echo "ERROR. No such directory exist: $1"
	printf "\n"
	exit -2
elif [ $3 == "/" ]; then
	## The 3rd parameter corresponds to the root folder. We change it to an empty string for compatibility.
	base_folder="$1"
  bucket_name="$2"
  aws_base_folder=""
elif [ ! -d "$4" ]; then
  printf "\n"
  echo "No AWS profile provided. Using the [default] profile"
  printf "\n"
  aws_profile="[default]"
else
	# This variable behaves as a constant. It stores the root path where all files are stored in AWS.
	base_folder="$1"
	bucket_name="$2"
	aws_base_folder="$3"
  aws_profile="$4"
fi


#########################
## Get script abs path ##
#########################

path=$(realpath "${BASH_SOURCE:-$0}")
dir_path=$(dirname $path)


########################
## Create log file
########################

if [ ! -d ./logs ]; then
  mkdir -p ./logs;
fi

log_file=./logs/S3_integrity_log
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
log_file=$log_file.$current_time.$2.txt
echo "Log filename: " "$log_file"


########################
## Main function
########################

function upload_s3
{
	# Receive parameters
	local_folder="$1"

	## Declare variables
	etag_value=""

	################################################
	## Loop through the files from the local folder
	################################################

	for i in "$local_folder"/*
	do

		if [ -d "$i" ]; then
			## THE LOCAL OBJECT IS A DIRECTORY
			upload_s3 "$i"

		elif [ -f "$i" ]; then
			## THE LOCAL OBJECT IS A FILE

			# Remove the base folder from the local file path to have the AWS path corresponding to the current local file
			aws_file_path=${i#"$base_folder"}

			## Remove the first first "/" character if it exists
			if [[ $aws_file_path == /* ]]; then
				aws_file_path=${aws_file_path#"/"}
			fi

			# Build the AWS path corresponding to the current local file
			aws_file_path=$aws_base_folder$aws_file_path

			## Check the file size and generate the ETag value
			file_size="$(stat --printf="%s" "$i")"
			if [ "$file_size" -lt 8000000 ]; then
				etag_value="$(md5sum "$i" | awk '{ print $1 }')"
			else
				etag_value="$($dir_path/s3md5/s3md5 8 "$i")"
			fi

			#################################################
			## Variables that might be useful to double-check
			#################################################
			#echo $etag_value
			#echo "$aws_file_path"
			#echo $bucket_name
			#echo $file_size


			## Compare the AWS file ETag value with the one we have generated from the local file

			aws_response="$(aws s3api head-object --bucket "$bucket_name" --key "$aws_file_path" --if-match "$etag_value" --profile "$aws_profile")"
			## Save results in a log file
			if [[ $aws_response == *"ETag"* ]]; then
				echo "$aws_file_path": "CORRECT"
  				echo "CORRECT: $aws_file_path - $etag_value" >> "${log_file}"
			else
				echo "$aws_file_path": "ERROR"
				echo "ERROR: $aws_file_path - $etag_value - $aws_response" >> "${log_file}"
			fi
		fi
	done
}

## Request the function
upload_s3 "${1}"
