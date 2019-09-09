aws_check_integrity
=====

Bash script to check the integrity of a set of files which have already been uploaded into an AWS S3 bucket.



Description
===========

Considering that our local directory path is the same than the one existing on the S3 bucket (because it’s supposed that all its files have previously been uploaded into the bucket by using the sync command), the script will: 

1. Loop through the files in our local directory. 

2. Per each file found in the local folder the script will check its size (if the object found is a directory it will just continue looping through their children files): 

  2.1.If the file size is smaller than 8MG, it will generate a simple MD5 digest. 

  2.2. If the file size is bigger than 8MG, it will make a request to a s3md5 function (https://github.com/antespi/s3md5 - author: Antonio Espinosa) which will apply the same algorithm than AWS does: it will split the file into 8MG little parts, generate the MD5 hash of each little part and, finally, will generate the final MD5 digest number from the set of individual MD5 hashes.

3. Retrieve the ETag number from the file with the same name stored on the S3 bucket. 

4. Compare that ETag number with the one we have just generated. 

  4.1. If both are equals, we can confirm the integrity of the file stored on the S3 bucket. Otherwise, the script will generate an error. In both cases, the result is stored in a log file which name is S3_integrity_log.[timestamp].txt. 



Usage
=====
```

1. First, download s3md5 project (https://github.com/antespi/s3md5) into the aws_check_integrity folder.

2. Next:

Usage : aws_check_integrity.sh <local_path> <bucket_name> <folder>

- local_path: local path of our server where all previously uploaded files are currently stored. For example: /data/nucCyt/raw_data/. 

- bucket_name: the name of the S3 bucket we want to check. For example: nuccyt. 

- folder: the name of the root folder on the S3 bucket. If there is not any folder in the root, this parameter will be a slash (/) indicating the root path. For example, raw_data/. 
```


Example
=======

aws_check_integrity.sh /data/nucCyt/raw_data/ nuccyt raw_data/



LICENSE
=======

aws_check_integrity is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

aws_check_integrity is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with aws_check_integrity. GPLv3 from [GNU Licenses](http://www.gnu.org/licenses/).



AUTHOR
======

Copyright (C) 2019<br />
Sonia García Ruiz<br />
Email    : s.ruiz@ucl.ac.uk<br />
Web      : [Rytenlab](https://www.rytenlab.com)
