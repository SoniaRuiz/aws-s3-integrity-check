[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.8217517.svg)](https://doi.org/10.5281/zenodo.8217517)

# aws-s3-integrity-check

Bash tool to verify the integrity of a dataset uploaded/downloaded to/from an Amazon S3 bucket.

## Publication


**aws-s3-integrity-check: an open-source bash tool to verify the integrity of a dataset stored on Amazon S3**

*Sonia García-Ruiz, Regina Hertfelder Reynolds, Melissa Grant-Peters, Emil Karl Gustavsson, Aine Fairbrother-Browne, Zhongbo Chen, Jonathan William Brenton, Mina Ryten*

Technical Release - [DOI 10.46471/gigabyte.87](https://gigabytejournal.com/articles/87)

![https://gigabytejournal.com/assets/img/gs_cover_new.png](https://gigabytejournal.com/assets/img/gs_cover_new.png)

## Abstract

Amazon Simple Storage Service (Amazon S3) is a widely used platform for storing large biomedical datasets. Unintended data alterations can occur during data writing and transmission, altering the original content and generating unexpected results. However, no open-source and easy-to-use tool exists to verify end-to-end data integrity. Here, we present aws-s3-integrity-check, a user-friendly, lightweight, and reliable bash tool to verify the integrity of a dataset stored in an Amazon S3 bucket. Using this tool, we only needed ∼114 min to verify the integrity of 1,045 records ranging between 5 bytes and 10 gigabytes and occupying ∼935 gigabytes of the Amazon S3 cloud. Our aws-s3-integrity-check tool also provides file-by-file on-screen and log-file-based information about the status of each integrity check. To our knowledge, this tool is the only open-source one that allows verifying the integrity of a dataset uploaded to the Amazon S3 Storage quickly, reliably, and efficiently. The tool is freely available for download and use at [https://github.com/SoniaRuiz/aws-s3-integrity-check](https://github.com/SoniaRuiz/aws-s3-integrity-check) and [https://hub.docker.com/r/soniaruiz/aws-s3-integrity-check](https://hub.docker.com/r/soniaruiz/aws-s3-integrity-check).


## Additional Resources

[<img src="https://cdn.protocols.io/production/images/177sk/branding/branding.jpg" width="20%">](https://www.protocols.io/view/check-the-integrity-of-a-dataset-stored-on-amazon-n92ld9qy9g5b/v2)

* DockerHub: [https://hub.docker.com/r/soniaruiz/aws-s3-integrity-check](https://hub.docker.com/r/soniaruiz/aws-s3-integrity-check)

  
## Description

The **aws_check_integrity.sh** bash script does:

1. Check whether the user has provided all required parameters as expected.
2. Check whether the user has successfully authenticated on AWS and if he/she has enough permissions to read the files stored within the S3 bucket indicated by the parameter '-b|--bucket <bucket_name>'.
3. Connect to the bucket '-b|--bucket <bucket_name>' and read the metadata of all the objects it stores.
4. Per each file found within the local folder provided ('l|--local <local_folder>'), the script checks the file size. In case the object found is a directory, it recursively loops across the objects it contains until it finds a file:
   * If the file size is smaller than 8MG, this tool generates an MD5 digest value of its contents.
   * If the file size is larger than 8MG, it uses the tool [s3md5](https://github.com/antespi/s3md5) (author: [Antonio Espinosa](https://github.com/antespi)) to produce an ETag number of the file contents. Briefly, the [s3md5](https://github.com/antespi/s3md5) tool (1) splits the contents of the provided file into chunks of 8 MB each, (2) generates the MD5 hash value corresponding to each chunk and (3) generates a final MD5 digest number by combining all individual MD5 hashes produced, resulting in an ETag number.
5. Next, the *aws_check_integrity.sh* bash script loops through the metadata downloaded from AWS (step 1) and tries to find a file with the same ETag value and file name as the ETag value and file name of the local file being tested.
6. If both local and remote ETag numbers and file names are identical, the script can confirm the integrity of the S3 version of the local file tested. On the contrary, the script will produce an error message. In both cases, the result will be logged within a local log file with the following name pattern: *bucket_name.S3_integrity_log.timestamp_bucketname.txt*. The log file will be stored within a folder called 'logs', which the script will automatically create within the path where the *aws-s3-integrity-check.sh* file is located in case the folder doesn't exist yet.

## Prerequisites

1. Install [**jq**](https://stedolan.github.io/jq/) software.
2. Install [**xxd**](https://manpages.ubuntu.com/manpages/bionic/en/man1/xxd.1.html) software, version 1.10 27oct98 by Juergen Weigert.
2. Clone [**s3md5**](https://github.com/antespi/s3md5) GitHub repository.
```bash
$ git clone https://github.com/antespi/s3md5.git
```
3. Install AWS Command Line Interface (CLI). [More info](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
4. Authenticate on AWS using AWS CLI. Depending on the authentication mode chosen, the AWS command to use will differ:
    * **aws configure**: if you log in on AWS using an IAM role (KEY + SECRET). [More info](https://docs.aws.amazon.com/cli/latest/reference/configure/).
    * **aws configure sso**: if you login on AWS using the AWS Single Sign-On (SSO) service. [More info](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/configure/sso.html).

**IMPORTANT:** for the correct function of this *aws_check_integrity.sh* tool, you should choose **JSON** as the output format during the authentication process. 

## Installation

1. Once you have cloned the [**s3md5**](https://github.com/antespi/s3md5) GitHub repository, you will need to grant execution access to the s3md5 bash script file.
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

## Example

```sh
$ bash aws_check_integrity.sh --local /data/nucCyt/ --bucket nuccyt --profile my_aws_profile
```

## Limitations

This tool presents the following limitations:

* The user has to have read/write access to an Amazon S3 bucket. 
* This tool requires that the user selects JavaScript Object Notation (JSON) as the preferred text-output format during the AWS authentication process.
* The aws-s3-integrity-check tool is only expected to work for files that have been uploaded to Amazon S3 by using any of the aws s3 transfer commands available (i.e. cp, sync, mv, and rm) with all the configuration parameters set to default values (including multipart_threshold and multipart_chunksize); it is essential that the file size threshold for the file multipart upload and the default multipart chunk size remain at the default 8 MB values.
* The bash version of this tool is only expected to work across Linux distributions.
* The Dockerized version of this tool requires three extra arguments to mount three local folders required by the Docker image, which may increase the complexity of using this tool.

## Docker image

To remove the OS dependency, this tool has been made available in a Docker format. The details regarding how to download, run and use the Dockerised version of the '*aws-s3-integrity-check*' bash tool can be found on DockerHub [here](https://hub.docker.com/r/soniaruiz/aws-s3-integrity-check).

## Testing

The aws-s3-integrity-check tool is expected to work only across Linux distributions. With this in mind, testing was successfully performed on the following Ubuntu versions:

* Ubuntu 16.04.6 LTS (Xenial Xerus)
* Ubuntu 22.04.2 LTS (Jammy Jellyfish)

## Support 

This aws-s3-integrity-check GitHub repository allows recording new issues and submitting tested pull requests for review. Issues on this repository have been configured to create triaged and labelled entries by choosing between the **Bug report** or **Feature request** categories, ultimately facilitating the creation and submission of issues.

The *aws-s3-integrity-check* tool relies on the s3md5 bash script (version 1.2, https://github.com/antespi/s3md5) to function. To ensure the availability and maintenance of the s3md5 bash script to the users of the *aws-s3-integrity-check* tool, the [source s3md5](https://github.com/antespi/s3md5) GitHub repository has been forked and made available at https://github.com/SoniaRuiz/s3md5. Any potential issues emerging on the s3md5 bash script that may affect the core and correct function of the aws-s3-integrity-check tool can be submitted via the Issues tab of the [forked s3md5](https://github.com/SoniaRuiz/s3md5/issues) repository. Any created issue will be triaged, maintained and fixed on the forked GitHub repository before being submitted via a pull request to the project owner.




## AUTHOR

Copyright (C) 2023<br />
[Sonia García-Ruiz](https://github.com/SoniaRuiz)<br />
Email Address: s.ruiz@ucl.ac.uk<br />
Website: [Rytenlab](https://rytenlab.com/)

