[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5012285.svg)](https://doi.org/10.5281/zenodo.5012285)

# aws-s3-integrity-check

Bash tool to verify the integrity of a dataset uploaded/downloaded to/from an Amazon S3 bucket.

## Prerequisites

1. Install [**'jq'** software](https://stedolan.github.io/jq/)
2. Download [**s3md5**](https://github.com/antespi/s3md5) GitHub repository.
```bash
$ git clone https://github.com/antespi/s3md5.git
```
3. Install AWS Command Line Interface (CLI). [More info](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
4. Log in into your AWS account through AWS CLI. Depending on the authentication mode chosen, the AWS command to use will differ:

* aws configure: if you login on AWS using an IAM role (KEY + SECRET).
* aws configure sso: if you login on AWS using the AWS Single Sign-On (SSO) service.

**IMPORTANT:** for the correct function of this *aws_check_integrity.sh* tool, you should choose **JSON** as the output format during the authentication process. 

## Installation

1. Once you have cloned the [**s3md5**](https://github.com/antespi/s3md5) GitHub repository, you will need to grant execution access to he s3md5 bash script file.
```sh
$ chmod 755 ./s3md5/s3md5
```
2. Clone the **aws-s3-integrity-check** GitHub repository:
```sh
$ git clone https://github.com/SoniaRuiz/aws-s3-integrity-check.git
```
3. Move the *s3md5* folder within the *aws-s3-integrity-check* folder:
```sh
$ mv ./s3md5 ./aws-s3-integrity-check
```
4. The contents of the *aws-s3-integrity-check* folder should look similar to the following:
```sh
total 16
-rw-r--r-- 1 your_user your_group 3573 date README.md
-rwxr-xr-x 1 your_user your_group 3301 date aws_check_integrity.sh
drwxr-xr-x 2 your_user your_group 4096 date s3md5
```
5. Run the script 'aws_check_integrity.sh' bash script by following the instructions below:

```bash
$ bash aws_check_integrity.sh [-l|--local <local_folder>] [-b|--bucket <bucket_name>] [-p|--profile <aws_profile>]\n

Options:
* -l|--local    <local_folder>  [required] Path to a local folder containing the original version of the files uploaded to Amazon S3. Example: -l /data/nucCyt/raw_data/
* -b|--bucket   <bucket_name>   [required] Amazon S3 bucket containing the files uploaded from the local folder '-l <local_folder>'. Example: -b nuccyt
* -p|--profile  <aws_profile>   [optional] AWS profile in case the user has logged in using the command *aws configure sso*. Example: -p my_aws_profile
* -h|--help                     [optional] Shows further help options "

```

## Description

The **aws_check_integrity.sh** bash script does:

1. Checks the user has indicated all the parameters that are required and that they contain the type of data expected.

2. Checks that the user has authenticated on AWS and that it has read permissions over the files of the bucket indicated.

3. Connects to the bucket '-b|--bucket <bucket_name>' and reads the metadata of all the objects it stores.

4. Per each file found in the local folder indicated 'l|--local <local_folder>', the script checks its size (in case the object found is a directory, it will loop within it until finding a file):

   * If the size of the file found is smaller than 8MG, this tool will generate a simple MD5 digest value.
   * If the size of the file found is bigger than 8MG, this tool will make a request to the [s3md5](https://github.com/antespi/s3md5) function (author: [Antonio Espinosa](https://github.com/antespi)) which will apply the same algorithm as AWS does: it will (1) split the file into smaller 8MG chunks, (2) generate the MD5 hash corresponding to each file chunk and (3) generate a final MD5 digest number by combining the set of individual MD5 hashes, namely ETag number.

5. Find within the metadata object downloaded in step 1) a file with the same ETag value and file name than the ETag value and file name of the local file being tested.

6. If both ETag numbers and file names are identical, the script will confirm the integrity of the file stored on the AWS S3 bucket. On the contrary, the script will generate an error. In both cases, the result will be stored within a log file with the following name pattern: *bucket_name.S3_integrity_log.timestamp_bucketname.txt*. The log file will be stored within a folder called 'logs', which the script will automatically create within the path where the *aws-s3-integrity-check.sh* file is located in case the folder doesn't exist yet.


## Example

```sh
$ bash aws_check_integrity.sh --local /data/nucCyt/ --bucket nuccyt --profile my_aws_profile
```

## Supported platforms

This bash tool has been successfully tested on:

* Ubuntu 16.04.6 LTS (Xenial Xerus)
* Ubuntu 22.04.2 LTS (Jammy Jellyfish)

## Data Availability

This tool is available on:

* protocols.io
* DockerHub: [https://hub.docker.com/r/soniaruiz/aws-s3-integrity-check](https://hub.docker.com/r/soniaruiz/aws-s3-integrity-check)

## AUTHOR

Copyright (C) 2021<br />
[Sonia García-Ruiz](https://github.com/SoniaRuiz)<br />
Email : s.ruiz@ucl.ac.uk<br />
Web   : [Rytenlab](https://rytenlab.com/)

