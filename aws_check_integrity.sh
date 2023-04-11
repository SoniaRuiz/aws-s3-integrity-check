#!/bin/bash
#echo "First arg: $1 <local_path>"
#echo "Second arg: $2 <bucket_name>"
#echo "Third arg: $3 <bucket_folder>"
#echo "Fouth arg: $4 <aws_profile>"

#########################
## Prerrequisites
########################

# 1. The user must be already connected to S3
# 2. The local directory must have beeen sincronised with AWS by using the "sync" command


####################################################################
## Get the absolute path of this script within the local computer ##
####################################################################

path=$(realpath "${BASH_SOURCE:-$0}")
dir_path=$(dirname $path)

# 
# result="$("$dir_path"/s3md5/s3md5.sh 8 "$dir_path"/s3md5/readme.txt 2>&1)"
# echo "$result"
# exit -1

#########################
## Receive parameters
#########################

local_folder=""
bucket_name=""
aws_base_folder=""
aws_profile=""

print_aws_login() {
  printf "EXAMPLE :\n 
	* aws configure
	* aws configure sso
	* More info: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html\n\n"
	
}
print_usage() {
  printf "USAGE :\n aws_check_integrity.sh -l <local_path> -b <bucket_name> -r <bucket_folder> -p <aws_profile>
	* -l <local_folder>: [required] local folder that contains the original files uploaded to AWS. Example: -l \"/data/nucCyt/raw_data/\"
	* -b <bucket_name>: [required] AWS S3 bucket that contains the uploaded files we want to check. Example: -b \"nuccyt\".
	* -r <bucket_folder>: [optional] the name of the folder within the S3 bucket that is currently storing the files to check. Example: -r \"fccyt\".
	* -p <aws_profile>: [optional] your AWS profile. Example: -p \"my_profile\"\n\n"
}

while getopts "l:b:r:p:" arg; do
  case $arg in
    l) local_folder=$OPTARG;;
    b) bucket_name=$OPTARG;;
    r) aws_base_folder=$OPTARG;;
    p) aws_profile=$OPTARG;;
    ?) print_usage
       exit 1 ;;
  esac
done

#printf "$local_folder"
#printf "$bucket_name"
#printf "$aws_base_folder"
#printf "$OPTIND"


#shift $((OPTIND-1))
#echo "$# non-option arguments"

if [ $OPTIND -eq 1 ]; then 
  printf "\n"
	echo "ERROR: The arguments '-l <local_path>' and '-b <bucket_name>' are required!"
	printf "\n"
	print_usage
	exit -2
elif [ "$local_folder" = '' ]; then
	printf "\n"
	echo "ERROR: The argument '-l' is required!"
	printf "\n"
	print_usage
	exit -2
elif [ ! -d "$local_folder" ]; then
	printf "\n"
	echo "ERROR. No such directory exist: $local_folder"
	printf "\n"
	exit -2
elif [ "$bucket_name" = '' ]; then
	printf "\n"
	echo "ERROR: The argument '-b' is required!"
	printf "\n"
	print_usage
	exit -2
fi

####################################################################
## TEST THE CONNECTION TO AWS
####################################################################

printf "aws_profile"
if [ "$aws_profile" = "" ]; then
  RESULT="$(aws s3 ls 2>&1)"
else
  RESULT="$(aws s3 ls --profile "$aws_profile" 2>&1)"
fi 


## Remove the first first "/" character if it exists
if [ "$RESULT" = "*error*" ]; then
  printf "\n"
	echo "ERROR: It has not been possible to stablish connection with AWS.\n\nDid you forget to include '--profile your_aws_profile'?"
	printf "\n"
	print_aws_login
  exit 1
fi


########################
## Create log file
########################
echo "logs"
# if [ ! -d "$dir_path/logs" ]; then
#   mkdir -p "$dir_path/logs";
# fi


log_file="$dir_path/logs/$bucket_name.S3_integrity_log"
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
log_file=$log_file.$current_time.txt
echo "Log filename: " "$log_file"



##############################################
## RECIEVE FROM AWS ALL ETAG VALUES AT ONCE ##
##############################################

echo $(date "+%T Reading objects metadata from AWS...")

aws_bucket_all_files="$(aws s3api list-objects --bucket "$bucket_name" --profile "$aws_profile" 2>&1)"

if [ "$aws_bucket_all_files" = "*error*" ]; then
  printf "\n"
	echo "ERROR: It has not been possible to read data from $bucket_name bucket.\n\nDo you have read access to bucket $bucket_name?"
	printf "\n"
  exit 1
else
  echo $(date "+%T Metadata read!")
fi

echo "$aws_bucket_all_files"
exit -1
########################
## Main function
########################
total_file_size_processed=''

upload_s3() {
  
  #echo "$local_folder"/*	# Receive parameters
	local_folder="$1"

	## Declare variables
	etag_value=""

	################################################
	## Loop through the files from the local folder
	################################################

  aws_folder=""
	for i in $(find "$local_folder"/* -type f -print)
	do
	
	  ## THE LOCAL OBJECT IS A FILE
		if [ -f "$i" ]; then
		
			## GET THE REMOTE AWS PATH CORRESPONDING TO THE LOCAL FILE
			
			file_name="${i#*//}"

      ## CHECK WHETHER THE LOCAL FILE EXISTS ON AWS
      
      result=$(echo "$aws_bucket_all_files" | jq -r '.Contents[] | select((.Key | contains ("'$file_name'")) ) | .Key ' 2>&1)
      
      if [[ "$result" == "" ]]; then
        echo $(date "+%T - FILE NOT FOUND: file '$i' not found within the bucket '$bucket_name' on AWS!") 
        echo $(date "+%T - FILE NOT FOUND: file '$i' not found within the bucket '$bucket_name' on AWS!") >> "${log_file}"
      else
      
        ## CALCULATE THE ETAG VALUE FOR THE LOCAL FILE
        
        file_size="$(stat --printf="%s" "$i")"
        
        ## Total filesize proccessed
  	    if [[ "$total_file_size_processed" == "" ]]; then
  	      total_file_size_processed=$file_size
  	    else
  	      total_file_size_processed=$(( $file_size + $total_file_size_processed ))
  	    fi
  	    
  	    ## Let the user know in case the file is too large
  	    file_size_HR=$(echo "$file_size" | numfmt --to=iec)
  			if [ "$file_size" -gt 500000000 ]; then
  			  echo "Calculating the ETag value for a large file: $file_size_HR ..." 
  			fi
  			
  			## Calculate the ETag value
  			if [ "$file_size" -lt 8000000 ]; then
  				etag_value="$(md5sum "$i" | awk '{ print $1 }')"
  			else
  		
  				etag_value="$(bash $dir_path/s3md5/s3md5.sh 8 "$i")"
  			fi
  			

        ## COMPARE THE LOCAL AND REMOTE ETAG VALUES
        
        result=$(echo "$aws_bucket_all_files" | jq -r '.Contents[] | select((.ETag ==  "\"'$etag_value'\"") and (.Key | contains ("'$file_name'")) ) | .Key ' 2>&1)
        if [[ "$result" == "" ]]; then
          echo $(date "+%T - ERROR: the ETag number for the file '$i' do not match. File potentially corrupt.") 
          echo $(date "+%T - ERROR: the ETag number for the file '$i' do not match. File potentially corrupt.") >> "${log_file}"
        elif [[ "$result" == "*error*" ]]; then
          echo $(date "+%T - ERROR: '$result'.") 
          echo $(date "+%T - ERROR: '$result'.") >> "${log_file}"
        else
          echo $(date "+%T - CORRECT: $file_name - file_size: $file_size_HR ")
          echo $(date "+%T - CORRECT: $file_name - file_size: $file_size_HR ") >> "${log_file}"
        fi
        
      fi
    
		fi
		
	done
}

## Request the function
upload_s3 "$local_folder" "$bucket_name" "$aws_profile"

## For stats, store the total file size processed
total_file_size_processed_HR=$(echo "$total_file_size_processed" | numfmt --to=iec)
echo $(date "+%T - FILE PROCESSING FINISHED! $total_file_size_processed_HR processed. ") >> "${log_file}"
