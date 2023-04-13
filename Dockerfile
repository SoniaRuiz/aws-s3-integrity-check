FROM ubuntu:bionic

LABEL maintainer="SoniaGR <s.ruiz@ucl.ac.uk>"

RUN apt-get update && apt-get install -y --no-install-recommends

## Install the jq dependency (used to process JSON metadata)
RUN apt-get install -y jq

## Install the xxd dependency (used to convert to hexadecimal notation)
RUN apt-get install -y xxd

## Copy and RUN the AWS CLI installer dependency (used to communicate with AWS)
COPY ./aws /usr/src/aws
RUN /usr/src/aws/install

## Copy and RUN the s3md5 tool dependency (used to calculate ETag number of file multiparts)
RUN mkdir /usr/src/s3md5
COPY ./s3md5/* /usr/src/s3md5/
RUN chmod -R 777 /usr/src/s3md5

## Copy the aws-s3-integrity-check tool and grant permissions
COPY ./aws_check_integrity.sh /usr/src/aws_check_integrity.sh
RUN chmod 755 /usr/src/aws_check_integrity.sh

## Create folder to store the logs
RUN mkdir /usr/src/logs
RUN chmod 755 /usr/src/logs

ENTRYPOINT ["/usr/src/aws_check_integrity.sh"]
