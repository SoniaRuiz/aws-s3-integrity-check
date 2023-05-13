#!/bin/bash
# aws-s3-integrity-check  Copyright (C) 2023
#        Sonia García-Ruiz <sruiz at ucl dot ac dot uk>
#
# aws-s3-integrity-check is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# aws-s3-integrity-check is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with aws-s3-integrity-check.  If not, see <http://www.gnu.org/licenses/>.


#echo "First arg: $1 <local_path>"
#echo "Second arg: $2 <bucket_name>"
#echo "Third arg: $3 <bucket_folder>"
#echo "Fouth arg: $4 <aws_profile>"

#########################
## Prerrequisites
########################

# 1. The local directory "-l <local_folder>" must have beeen sincronised with the 
#    "-b <bucket_name>" Amazon S3 bucket by using the "sync" command.
# 2. The user must have already authenticated to Amazon S3, i.e. "aws configure" or "aws configure sso".
# 3. The user must have access permissions to the "-b <bucket_name>" Amazon S3 bucket.

####################################################################
## Get the absolute path of this script within the local computer ##
####################################################################

path=$(realpath "${BASH_SOURCE:-$0}")
dir_path=$(dirname $path)

######################################
## Receive and evaluate parameters
######################################
printf "\n"
local_folder=""
bucket_name=""
aws_profile=""

print_aws_login() {
  printf "\n
  EXAMPLE: 
	\taws configure
	\taws configure sso
	\tMore info: https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html\n\n"
	
}
usage() {
  printf "\n
  USAGE
  \t[bash aws_check_integrity.sh] Verifies the integrity of a set of files uploaded/downloaded to/from Amazon S3.\n
  SYPNOSIS\n
  \tbash aws_check_integrity.sh [-l|--local <local_path>] [-b|--bucket <bucket_name>] [-p|--profile <aws_profile>]\n
  DESCRIPTION\n
  \tVerifies the integrity of a set of files uploaded/downloaded to/from Amazon S3.\n
  \tUsing one single query to Amazon S3, it downloads all the ETag numbers associated with the files contained within a particular Amazon S3 bucket. 
  \tFor each file stored within a local folder, it uses the s3md5 tool to calculate the Etag number corresponding to its data contents and then compare this number with the ETag value downloaded from Amazon S3.
  \tIf both ETag numbers are identical, the integrity of the file is proven.
  
  \tOptions:
    \t\t-l|--local    <local_folder>  [required] Path to a local folder containing the original version of the files uploaded to Amazon S3. Example: -l /data/nucCyt/raw_data/
    \t\t-b|--bucket   <bucket_name>   [required] Amazon S3 bucket containing the files uploaded from the local folder '-l <local_folder>'. Example: -b nuccyt
    \t\t-p|--profile  <aws_profile>   [optional] AWS profile in case the user has logged in using the command *aws configure sso*. Example: -p my_aws_profile
    \t\t-h|--help                     [optional] Shows further help options \n\n"
  exit 1
}


for arg in "$@"; do
  shift
  case "$arg" in
    '--local')   set -- "$@" '-l'   ;;
    '--bucket') set -- "$@" '-b'   ;;
    '--profile')   set -- "$@" '-p'   ;;
    '--help')   set -- "$@" '-h'   ;;
    '--'*) usage exit 1 ;;
    *) set -- "$@" "$arg" ;;
  esac
done

#echo "$arg"

while getopts "l:b:p:h" arg; do
  case $arg in
    l) local_folder=$OPTARG;;
    b) bucket_name=$OPTARG;;
    p) aws_profile=$OPTARG;;
    ?) usage ;;
  esac
done

if [ $OPTIND -eq 1 ]; then 
  printf "\n"
	echo "ERROR: The arguments '-l <local_path>' and '-b <bucket_name>' are required!"
	usage 
	exit -2
elif [ "$local_folder" = '' ]; then
	printf "\n"
	echo "ERROR: The argument '-l' or '--local' is required!"
	usage 
elif [ ! -d "$local_folder" ]; then
	printf "\n"
	echo "ERROR. No such directory exist: $local_folder"
	printf "\n"
elif [ "$bucket_name" = '' ]; then
	printf "\n"
	echo "ERROR: The argument '-b' or '--bucket' is required!"
	usage 
	printf "\n"
fi

####################################################################
## TEST THE CONNECTION TO AWS
####################################################################

if [ "$aws_profile" = "" ]; then
  RESULT="$(aws s3 ls 2>&1)"
else
  RESULT="$(aws s3 ls --profile "$aws_profile" 2>&1)"
fi 

## Check AWS response
if [ "$RESULT" = "*error*" ]; then
  printf "\n"
	echo "ERROR: It has not been possible to stablish connection with AWS."
	echo "  - Did you forget to include '--profile your_aws_profile'?"
	echo "  - Did you forget to mount the folder containig the AWS credentials?"
	echo "$RESULT"
	printf "\n"
	print_aws_login
  exit 1
elif [[ "$RESULT" == *"could not be found"* ]]; then
  printf "\n"
	echo "ERROR: It has not been possible to stablish connection with AWS."
	echo "  - Did you forget to include '--profile your_aws_profile'?"
	echo "  - Did you forget to mount the folder containig the AWS credentials?"
	echo "$RESULT"
	printf "\n"
  exit -1
fi


########################
## Create log file
########################

if [ ! -d "$dir_path/logs" ]; then
  mkdir -p "$dir_path/logs";
fi


log_file="$dir_path/logs/$bucket_name.S3_integrity_log"
current_time=$(date "+%Y.%m.%d-%H.%M.%S")
log_file=$log_file.$current_time.txt
echo "Log filename: " "$log_file"



##############################################
## RECIEVE FROM AWS ALL ETAG VALUES AT ONCE ##
##############################################

echo $(date "+%T Reading objects metadata from Amazon S3 ...")

aws_bucket_all_files="$(aws s3api list-objects --bucket "$bucket_name" --profile "$aws_profile" 2>&1)"

if [[ "$aws_bucket_all_files" == *"Unable"* ]]; then
  printf "\n"
  echo "ERROR: $aws_bucket_all_files"
  printf "\n"
  exit -1
elif [[ "$aws_bucket_all_files" == *"error"* ]]; then
  printf "\n"
	echo "ERROR: It has not been possible to read data from $bucket_name bucket.\n\nDo you have read access to bucket $bucket_name?"
	printf "\n"
  exit -1
else
  echo $(date "+%T Metadata read!")
fi

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
			
			file_name="$(basename -- $i)"

      ## CHECK WHETHER THE LOCAL FILE EXISTS ON AWS
      
      result=$(echo "$aws_bucket_all_files" | jq -r '.Contents[] | select((.Key | contains ("'$file_name'")) ) | .Key ' 2>&1)
      
      if [[ "$result" == "" ]]; then
        echo $(date "+%T - FILE NOT FOUND: file '$i' not found within the Amazon S3 bucket '$bucket_name'.") 
        echo $(date "+%T - FILE NOT FOUND: file '$i' not found within the Amazon S3 bucket '$bucket_name'.") >> "${log_file}"
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
  			if [ "$file_size" -lt 8388608 ]; then
  				etag_value="$(md5sum "$i" | awk '{ print $1 }')"
  			else
  				etag_value="$($dir_path/s3md5/s3md5 8 "$i")"
  			fi
  			

        ## COMPARE THE LOCAL AND REMOTE ETAG VALUES
        
        result=$(echo "$aws_bucket_all_files" | jq -r '.Contents[] | select((.ETag ==  "\"'$etag_value'\"") and (.Key | contains ("'$file_name'")) ) | .Key ' 2>&1)
        if [[ "$result" == "" ]]; then

          echo $(date "+%T - ERROR: the ETag number for the file '$file_name' does not match. The local version of this file does not match its remote version on Amazon S3.") 
          echo $(date "+%T - ERROR: the ETag number for the file '$file_name' does not match. The local version of this file does not match its remote version on Amazon S3.") >> "${log_file}"

        elif [[ "$result" == "*error*" ]]; then
          echo $(date "+%T - ERROR: '$result'.") 
          echo $(date "+%T - ERROR: '$result'.") >> "${log_file}"
        else
          echo $(date "+%T - CORRECT: $file_name - file_size: $file_size_HR")
          echo $(date "+%T - CORRECT: $file_name - file_size: $file_size_HR - Local ETag: $etag_value") >> "${log_file}"
        fi
        
      fi
    
		fi
		
	done
}

## Request the function
upload_s3 "$local_folder" "$bucket_name" "$aws_profile"

## For stats, store the total file size processed
if [[ "$total_file_size_processed" == "" ]]; then
  total_file_size_processed="0"
fi

total_file_size_processed_HR=$(echo "$total_file_size_processed" | numfmt --to=iec)
echo $(date "+%T - FILE PROCESSING FINISHED! "$total_file_size_processed_HR" processed. ") >> "${log_file}"
