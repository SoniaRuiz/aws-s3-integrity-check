@test "testing that the lack of '--local' parameter produces an error ..." {

  run bash aws_check_integrity.sh --bucket tf-prioritizer --profile sruiz
  [ "$status" -eq 1 ]

}

@test "testing that passing a non-existent '--local' path produces an error ..." {

  run bash aws_check_integrity.sh --local non-existent-local-folder --bucket tf-prioritizer --profile sruiz
  [ "$status" -eq 1 ]

}

@test "testing that the lack of '--bucket' parameter produces an error ..." {

  run bash aws_check_integrity.sh --local ./102379-TF/ --profile non_existent_aws_profile
  [ "$status" -eq 1 ]

}

@test "testing that passing a non-existent '--bucket' produces an error ..." {

  run bash aws_check_integrity.sh --local ./102379-TF/ --bucket non-existent-bucket --profile sruiz
  [ "$status" -eq 1 ]

}

@test "testing that passing a non-existent '--profile' AWS profile produces an error ..." {

  run bash aws_check_integrity.sh --local ./102379-TF/ --bucket tf-prioritizer --profile non_existent_aws_profile
  [ "$status" -eq 1 ]

}

@test "testing integrity of the Amazon S3 bucket 'tf-prioritizer'..." {

  run bash aws_check_integrity.sh --local ./102379-TF/ --bucket tf-prioritizer --profile sruiz
  [ "$status" -eq 0 ]

}

@test "testing integrity of the Amazon S3 bucket 'mass-spectrometry-imaging'" {

  run bash aws_check_integrity.sh --local ./102374-Image/ftp.cngb.org/pub/gigadb/pub/10.5524/102001_103000/102374/ --bucket mass-spectrometry-imaging --profile sruiz
  [ "$status" -eq 0 ]
  
}

@test "testing integrity of the Amazon S3 bucket 'rnaseq-pd'" {

  run bash aws_check_integrity.sh --local /data/RNAseq_PD/ --bucket rnaseq-pd --profile sruiz
  [ "$status" -eq 0 ]
  
}




