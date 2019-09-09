#!/bin/bash
#echo "First arg: $1"
#echo "Second arg: $2"

# The user must be already connected to S3

# Receive parameters
base_folder="$1"
local_folder="$1"
bucket_name="$2"
aws_root_folder="$3"

#Create log file
log_file=S3_integrity_log
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
log_file=$log_file.$current_time.txt
echo "Log filename: " "$log_file"

# Loop through the directory
function upload_s3
{
	#echo $base
	local_folder="$1"
	bucket_name="$2"
	base="$3"
	etag_value=""

	for file in "$local_folder"/*; do
		#echo $file
		if [ -d "$file" ]; then
			#echo "Directory"
			directory="$(basename $file)"
			upload_s3 "$file" "$bucket_name" $base/$directory
		else

			## THE OBJECT IS A FILE
                        aws_file_path=${file#"$base_folder"}

			## Remove the first first / character if exists
			if [[ $aws_file_path == /* ]]; then
				aws_file_path=${aws_file_path#"/"}
			fi
			aws_file_path=$aws_root_folder$aws_file_path
                        #echo $aws_file_path

			## Check the file size and generate the ETag value
			file_size="$(stat --printf="%s" $file)"
			if [ "$file_size" -lt 8000000 ]; then
				#echo $file_size
				etag_value="$(md5sum ${file} | awk '{ print $1 }')"
			else
				etag_value="$(./s3md5 8 $file)"
			fi
			#echo $etag_value

			## Compare the AWS file ETag value with the one we have generated from the local file
			aws_response="$(aws s3api head-object --bucket $bucket_name --key $aws_file_path --if-match $etag_value)"
			## Save results in a log file
			if [[ $aws_response == *"ETag"* ]]; then
				echo $aws_file_path": CORRECT"
  				echo "CORRECT:"$aws_file_path" - "$etag_value >> $log_file
			else
				echo $aws_file_path": ERROR"
				echo "ERROR:"$aws_file_path" - "$etag_value  >> $log_file
			fi

		fi
	done
}


upload_s3 "$local_folder" "$bucket_name"

