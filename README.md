# aws_check_integrity

Bash script to check the integrity of a set of local files uploaded into an AWS S3 bucket.

## Prerequisites

1. Connect to your AWS account. For this purpouse, you may want to use **aws configure** command in your Linux terminal. This command is interactive, so the AWS CLI will prompt you to enter additional information.

   **IMPORTANT:** for the correct operation of this *aws_check_integrity.sh* script, **json** must be chosen as the preferred output format during the **aws configure** command execution.

```sh
> aws configure 

AWS Access Key ID [None]: your_AWS_access_key_ID 
AWS Secret Access Key [None]: your_AWS_secret_access_key 
Default region name [None]: your_default_region_name 
Default output format [None]: json 
```

2. Synchronize your local folder with your AWS bucket. For this purpouse, you may want to use the AWS CLI **sync** command as follows (we'll made use from the example below later in this file):

```sh
> aws s3 sync /data/nucCyt/raw_data s3://nuccyt 
```

## Description

Considering that our local directory path structure is the same one than the existing on our S3 bucket (please, check the 'Prerequisites' section above) **aws_check_integrity.sh** script will:

1. Loop through the set of files within our local directory.

2. Per each file found in the local folder the script will check its size (if the object found is a directory it will just continue looping through their children files):

   * If the file size is smaller than 8MG, it will generate a simple MD5 digest value.

   * If the file size is bigger than 8MG, it will make a request to a [s3md5](https://github.com/antespi/s3md5) function (author: [Antonio Espinosa](https://github.com/antespi)) which will apply the same algorithm as AWS does: it will split the file into 8MG little parts, generate the MD5 hash of each little part and, finally, will generate the final MD5 digest number from the set of individual MD5 hashes.

3. Retrieve the ETag value from the same file stored on the S3 bucket.

4. Compare the retrieved ETag value with the one we have just generated.

   * If both ETag numbers are equals, we can confirm the integrity of the file stored on the S3 bucket. Otherwise, the script will generate an error. In both cases, the result is stored in a log file which name will be S3_integrity_log.[timestamp].txt.



## Usage

1. First, download [**s3md5** project](https://github.com/antespi/s3md5) and store it within the *aws_check_integrity* folder.
2. Next, grant execution access to he s3md5 script file.
```sh
> cd aws_check_integrity
> chmod 755 ./s3md5/s3md5
```
3. Finally:
```
Usage : aws_check_integrity.sh <local_path> <bucket_name> <folder>

- local_path: local path of our server where all previously uploaded files are currently stored. For example: /data/nucCyt/raw_data/. 

- bucket_name: the name of the S3 bucket we want to check. For example: nuccyt. 

- bucket_folder: the name of the root folder on the S3 bucket. For example: raw_data. If there is not any folder in the root, this parameter will be a slash (/) indicating the root path. 
```


## Example

```sh
> aws_check_integrity.sh /data/nucCyt/raw_data/ nuccyt raw_data/
```

## Supported platforms

This script has been successfully tested on:

* Ubuntu 16.04.6 LTS (Xenial Xerus)

## AUTHOR

Copyright (C) 2020<br />
[Sonia García Ruiz](https://github.com/SoniaRuiz)<br />
Email : s.ruiz@ucl.ac.uk<br />
Web   : [Rytenlab](https://rytenlab.com/)

