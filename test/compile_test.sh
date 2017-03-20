#!/bin/sh
. ${BUILDPACK_HOME}/test/helper.sh

test_compile_with_defaults() {
  ENGINE_FIXTURE_DIR="$BUILDPACK_HOME/test/fixtures/predictionio-engine-classification-4.0.0"
  cp -r $ENGINE_FIXTURE_DIR/* $ENGINE_FIXTURE_DIR/.[!.]* $BUILD_DIR

  unset PREDICTIONIO_DIST_URL
  unset PIO_BUILD_SPARK_VERSION

  compile

  assertEquals "\`pio build\` exit code was ${RETURN} instead of 0" "0" "${RETURN}"
  assertTrue "missing Procfile" "[ -f $BUILD_DIR/Procfile ]"
  assertTrue "missing PostgreSQL driver" "[ -f $BUILD_DIR/lib/postgresql_jdbc.jar ]"
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

test_compile_with_predictionio_0_11_0_SNAPSHOT() {
  ENGINE_FIXTURE_DIR="$BUILDPACK_HOME/test/fixtures/predictionio-engine-classification-4.0.0"
  cp -r $ENGINE_FIXTURE_DIR/* $ENGINE_FIXTURE_DIR/.[!.]* $BUILD_DIR

  # Use the develop branch (0.11.0-SNAPSHOT) as of February 16, 2017,
  # until the "stateless build" feature is available in a release.
  export PREDICTIONIO_DIST_URL="https://marsikai.s3.amazonaws.com/PredictionIO-0.11.0-cb14625.tar.gz"
  unset PIO_BUILD_SPARK_VERSION

  compile

  assertEquals "\`pio build\` exit code was ${RETURN} instead of 0" "0" "${RETURN}"
  assertTrue "missing Procfile" "[ -f $BUILD_DIR/Procfile ]"
  assertTrue "missing PostgreSQL driver" "[ -f $BUILD_DIR/lib/postgresql_jdbc.jar ]"
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
  assertContains "PredictionIO 0.11.0-SNAPSHOT" "$(cat ${STD_OUT})"
  assertContains "Apache Spark 1.6.3" "$(cat ${STD_OUT})"
  assertContains "Meta Data Backend (Source: PGSQL)" "$(cat ${STD_OUT})"
  assertContains "Model Data Backend (Source: PGSQL)" "$(cat ${STD_OUT})"
  assertContains "Event Data Backend (Source: PGSQL)" "$(cat ${STD_OUT})"
  assertContains "Your system is all ready to go" "$(cat ${STD_OUT})"
}
