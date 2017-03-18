#!/bin/sh
. ${BUILDPACK_HOME}/test/helper.sh

pioEngineDir=""
pioSpy=""

# Create a spy script where the executable is expected
# to assert how it is called.
afterSetUp() {
  PATH=./:$PATH
  pioEngineDir="$BUILD_DIR/pio-engine"
  pioSpy="${pioEngineDir}/pio"
  mkdir -p "${pioEngineDir}"
  cat > $pioSpy <<'HEREDOC'
#!/bin/sh
set -e
echo $@
HEREDOC
  chmod +x $pioSpy

  cd $BUILD_DIR
  unset PIO_OPTS
  unset PIO_TRAIN_SPARK_OPTS
  unset PIO_S3_BUCKET_NAME
  unset PIO_S3_AWS_ACCESS_KEY_ID
  unset PIO_S3_AWS_SECRET_ACCESS_KEY
}

beforeTearDown() {
  cd $BUILDPACK_HOME
  rm $pioSpy
}

test_train_params()
{
  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-train
  assertEquals 0 ${rtrn}
  assertEquals \
    "train --" \
    "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_train_params_with_s3_bucket()
{
  export PIO_S3_BUCKET_NAME=example-bucket
  export PIO_S3_AWS_ACCESS_KEY_ID=YYYYY
  export PIO_S3_AWS_SECRET_ACCESS_KEY=ZZZZZ

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-train
  assertEquals 0 ${rtrn}
  assertEquals \
    "train -- --packages org.apache.hadoop:hadoop-aws:2.7.2" \
    "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_train_params_with_s3_bucket_missing_key()
{
  export PIO_S3_BUCKET_NAME=example-bucket

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-train
  assertEquals 0 ${rtrn}
  assertEquals \
    "train --" \
    "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_train_params_with_pio_opts()
{
  export PIO_OPTS='--variant best.json'
  
  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-train
  assertEquals 0 ${rtrn}
  assertEquals \
    "train --variant best.json --" \
    "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_train_params_with_spark_opts()
{
  export PIO_TRAIN_SPARK_OPTS='--master spark://localhost'
  
  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-train
  assertEquals 0 ${rtrn}
  assertEquals \
    "train -- --master spark://localhost" \
    "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}
