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
  unset PORT
  unset PIO_OPTS
  unset PIO_SPARK_OPTS
  unset PIO_ENABLE_FEEDBACK
  unset PIO_EVENTSERVER_HOSTNAME
  unset PIO_EVENTSERVER_ACCESS_KEY
  unset PIO_EVENTSERVER_APP_NAME
  unset PIO_S3_BUCKET_NAME
  unset PIO_S3_AWS_ACCESS_KEY_ID
  unset PIO_S3_AWS_SECRET_ACCESS_KEY
}

beforeTearDown() {
  cd $BUILDPACK_HOME
  rm $pioSpy
}

test_web_params()
{
  export PORT=853211
  
  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-web
  assertEquals 0 ${rtrn}
  assertEquals \
    "deploy --port 853211 --" \
    "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_web_params_missing_port()
{
  
  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-web
  assertEquals 1 ${rtrn}
  assertEquals "" "$(cat ${STD_OUT})"
  assertContains \
    "requires environment variable PORT" \
    "$(cat ${STD_ERR})"
}

test_web_params_with_s3_bucket()
{
  export PORT=853211
  export PIO_S3_BUCKET_NAME=example-bucket
  export PIO_S3_AWS_ACCESS_KEY_ID=YYYYY
  export PIO_S3_AWS_SECRET_ACCESS_KEY=ZZZZZ
  
  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-web
  assertEquals 0 ${rtrn}
  assertEquals \
    "deploy --port 853211 -- --packages org.apache.hadoop:hadoop-aws:2.7.2" \
    "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_web_params_with_s3_bucket_missing_key()
{
  export PORT=853211
  export PIO_S3_BUCKET_NAME=example-bucket
  
  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-web
  assertEquals 0 ${rtrn}
  assertEquals \
    "deploy --port 853211 --" \
    "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_web_params_with_pio_opts()
{
  export PORT=853211
  export PIO_OPTS='--variant best.json'
  
  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-web
  assertEquals 0 ${rtrn}
  assertEquals \
    "deploy --port 853211 --variant best.json --" \
    "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_web_params_with_spark_opts()
{
  export PORT=853211
  export PIO_SPARK_OPTS='--master spark://localhost'
  
  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-web
  assertEquals 0 ${rtrn}
  assertEquals \
    "deploy --port 853211 -- --master spark://localhost" \
    "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_web_params_with_feedback_enabled()
{
  export PORT=853211
  export PIO_ENABLE_FEEDBACK=true
  export PIO_EVENTSERVER_HOSTNAME=example.herokuapp.com
  export PIO_EVENTSERVER_ACCESS_KEY=XXXXX
  export PIO_EVENTSERVER_APP_NAME=sushi
  
  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-web
  assertEquals 0 ${rtrn}
  assertEquals \
    "deploy --port 853211 --feedback --event-server-ip example.herokuapp.com --event-server-port 443 --accesskey XXXXX --" \
    "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_web_params_with_feedback_missing_params()
{
  export PORT=853211
  export PIO_ENABLE_FEEDBACK=true
  
  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-web
  assertEquals 1 ${rtrn}
  assertEquals "" "$(cat ${STD_OUT})"
  assertContains \
    "missing required config: PIO_EVENTSERVER_APP_NAME=(missing) PIO_EVENTSERVER_HOSTNAME=(missing) PIO_EVENTSERVER_ACCESS_KEY=(missing)" \
    "$(cat ${STD_ERR})"
}
