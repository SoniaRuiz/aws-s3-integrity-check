FROM ubuntu:bionic

LABEL maintainer="SoniaGR <s.ruiz@ucl.ac.uk>"

RUN apt-get update && apt-get install -y --no-install-recommends
RUN apt-get install -y jq

COPY ./aws /usr/src/aws
RUN /usr/src/aws/install

COPY ./aws_check_integrity.sh /usr/src/aws_check_integrity.sh
RUN chmod 755 /usr/src/aws_check_integrity.sh

RUN mkdir /usr/src/s3md5
COPY ./s3md5/* /usr/src/s3md5/
RUN chmod -R 777 /usr/src/s3md5

RUN mkdir /usr/src/logs
RUN chmod 755 /usr/src/logs

ENTRYPOINT ["/usr/src/aws_check_integrity.sh"]
