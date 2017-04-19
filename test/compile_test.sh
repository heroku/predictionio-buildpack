#!/bin/sh
. ${BUILDPACK_HOME}/test/helper.sh

test_compile_with_predictionio_0_10_0() {
  ENGINE_FIXTURE_DIR="$BUILDPACK_HOME/test/fixtures/predictionio-engine-classification-4.0.0"
  cp -r $ENGINE_FIXTURE_DIR/* $ENGINE_FIXTURE_DIR/.[!.]* $BUILD_DIR

  # Existence triggers install of AWS SDK & Hadoop-AWS
  export PIO_S3_BUCKET_NAME="my-test-bucket"

  compile

  assertEquals "\`pio build\` exit code was ${RETURN} instead of 0" "0" "${RETURN}"
  assertTrue "missing Procfile" "[ -f $BUILD_DIR/Procfile ]"
  assertTrue "missing PostgreSQL JDBC" "[ -f $BUILD_DIR/pio-engine/PredictionIO-dist/lib/postgresql_jdbc.jar ]"
  assertTrue "missing AWS SDK" "[ -f $BUILD_DIR/pio-engine/PredictionIO-dist/lib/spark/aws-java-sdk.jar ]"
  assertTrue "missing Hadoop-AWS" "[ -f $BUILD_DIR/pio-engine/PredictionIO-dist/lib/spark/hadoop-aws.jar ]"
  assertTrue "missing runtime memory config" "[ -f $BUILD_DIR/.profile.d/pio-memory.sh ]"
  assertTrue "missing runtime path config" "[ -f $BUILD_DIR/.profile.d/pio-path.sh ]"
  assertTrue "missing runtime config renderer" "[ -f $BUILD_DIR/.profile.d/pio-render-configs.sh ]"
  assertTrue "missing web executable" "[ -f $BUILD_DIR/bin/heroku-buildpack-pio-web ]"
  assertTrue "missing train executable" "[ -f $BUILD_DIR/bin/heroku-buildpack-pio-train ]"
  assertTrue "missing release executable" "[ -f $BUILD_DIR/bin/heroku-buildpack-pio-release ]"
  assertTrue "missing data loader executable" "[ -f $BUILD_DIR/bin/heroku-buildpack-pio-load-data ]"
  expected_output="$BUILD_DIR/pio-engine/target/scala-2.10/template-scala-parallel-classification-assembly-0.1-SNAPSHOT-deps.jar"
  assertTrue "missing Scala build output: $expected_output" "[ -f $expected_output ]"

  echo "-----> Stage build for testing in /app/pio-engine (same as dyno runtime)"
  mv $BUILD_DIR/* $BUILD_DIR/.[!.]* /app/
  cd /app/pio-engine

  capture ./PredictionIO-dist/bin/pio status

  assertEquals "\`pio status\` exit code was ${RETURN} instead of 0" "0" "${RETURN}"
  assertContains "PredictionIO 0.10.0-incubating" "$(cat ${STD_OUT})"
  assertContains "Apache Spark 1.6.3" "$(cat ${STD_OUT})"
  assertContains "Meta Data Backend (Source: PGSQL)" "$(cat ${STD_OUT})"
  assertContains "Model Data Backend (Source: PGSQL)" "$(cat ${STD_OUT})"
  assertContains "Event Data Backend (Source: PGSQL)" "$(cat ${STD_OUT})"
  assertContains "Your system is all ready to go" "$(cat ${STD_OUT})"

  # Release process
  # capture /app/bin/heroku-buildpack-pio-release

  # Web process
  # capture /app/bin/heroku-buildpack-pio-web
}

SKIP_test_compile_with_predictionio_0_11_0() {
  ENGINE_FIXTURE_DIR="$BUILDPACK_HOME/test/fixtures/predictionio-engine-classification-4.0.0-pio-0.11.0"
  cp -r $ENGINE_FIXTURE_DIR/* $ENGINE_FIXTURE_DIR/.[!.]* $BUILD_DIR

  # Existence triggers install of AWS SDK & Hadoop-AWS
  export PIO_S3_BUCKET_NAME="my-test-bucket"

  compile

  assertEquals "\`pio build\` exit code was ${RETURN} instead of 0" "0" "${RETURN}"
  assertTrue "missing Procfile" "[ -f $BUILD_DIR/Procfile ]"
  assertTrue "missing PostgreSQL JDBC" "[ -f $BUILD_DIR/pio-engine/PredictionIO-dist/lib/postgresql_jdbc.jar ]"
  assertTrue "missing AWS SDK" "[ -f $BUILD_DIR/pio-engine/PredictionIO-dist/lib/spark/aws-java-sdk.jar ]"
  assertTrue "missing Hadoop-AWS" "[ -f $BUILD_DIR/pio-engine/PredictionIO-dist/lib/spark/hadoop-aws.jar ]"
  assertTrue "missing runtime memory config" "[ -f $BUILD_DIR/.profile.d/pio-memory.sh ]"
  assertTrue "missing runtime path config" "[ -f $BUILD_DIR/.profile.d/pio-path.sh ]"
  assertTrue "missing runtime config renderer" "[ -f $BUILD_DIR/.profile.d/pio-render-configs.sh ]"
  assertTrue "missing web executable" "[ -f $BUILD_DIR/bin/heroku-buildpack-pio-web ]"
  assertTrue "missing train executable" "[ -f $BUILD_DIR/bin/heroku-buildpack-pio-train ]"
  assertTrue "missing release executable" "[ -f $BUILD_DIR/bin/heroku-buildpack-pio-release ]"
  assertTrue "missing data loader executable" "[ -f $BUILD_DIR/bin/heroku-buildpack-pio-load-data ]"
  expected_output="$BUILD_DIR/pio-engine/target/scala-2.11/template-scala-parallel-classification-assembly-0.1-SNAPSHOT-deps.jar"
  assertTrue "missing Scala build output: $expected_output" "[ -f $expected_output ]"

  echo "-----> Stage build for testing in /app/pio-engine (same as dyno runtime)"
  mv $BUILD_DIR/* $BUILD_DIR/.[!.]* /app/
  cd /app/pio-engine

  capture ./PredictionIO-dist/bin/pio status

  assertEquals "\`pio status\` exit code was ${RETURN} instead of 0" "0" "${RETURN}"
  assertContains "PredictionIO 0.11.0-incubating" "$(cat ${STD_OUT})"
  assertContains "Apache Spark 2.1.0" "$(cat ${STD_OUT})"
  assertContains "Meta Data Backend (Source: PGSQL)" "$(cat ${STD_OUT})"
  assertContains "Model Data Backend (Source: PGSQL)" "$(cat ${STD_OUT})"
  assertContains "Event Data Backend (Source: PGSQL)" "$(cat ${STD_OUT})"
  assertContains "Your system is all ready to go" "$(cat ${STD_OUT})"
}
