#!/bin/sh
. ${BUILDPACK_HOME}/test/helper.sh

appBinDir=""
pioCommandSpy=""

# Create spy scripts where executables are expected
# to assert how they are called.
afterSetUp() {
  PATH=./bin:$PATH
  appBinDir="$BUILD_DIR/bin"
  appDataDir="$BUILD_DIR/pio-engine/data"
  pioCommandSpy="${appBinDir}/pio"
  mkdir -p "${appBinDir}"
  mkdir -p "${appDataDir}"
  mkdir -p "$BUILD_DIR/data"

  touch $pioCommandSpy
  chmod +x $pioCommandSpy

  cd $BUILD_DIR
}

beforeTearDown() {
  unset DATABASE_URL
  unset PIO_EVENTSERVER_APP_NAME
  unset PIO_EVENTSERVER_ACCESS_KEY
  unset AWS_REGION

  cd $BUILDPACK_HOME
  rm -f $pioCommandSpy $appDataDir/*
}

test_load_data_not_enabled()
{

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-load-data
  assertEquals 0 ${rtrn}
  assertEquals "" "$(cat ${STD_ERR})"
}

test_load_data_performs_initial_load()
{
  export DATABASE_URL=postgres://pio:pio@postgres:5432/pio
  export PIO_EVENTSERVER_APP_NAME=just-an-app
  export PIO_EVENTSERVER_ACCESS_KEY=12345
  cat > "$appDataDir/initial-events.json" <<'HEREDOC'
{"event":"$set","entity":"test","entityId":"0"}
HEREDOC
  cat > $pioCommandSpy <<'HEREDOC'
#!/bin/sh
if [ "$1" = "app" ] && [ "$2" = "show" ]
  then
  echo "Spy 'pio app show'"
  echo "App does not exist"
  exit 1
elif [ "$1" = "app" ] && [ "$2" = "new" ]
  then
  echo "Spy 'pio app new'"
  echo "ID: 358"
elif [ "$1" = "import" ]
  then
  echo "Spy 'pio $@'"
  echo "Events imported"
else
  exit 1
fi
HEREDOC

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-load-data
  assertEquals 0 ${rtrn}
  assertContains "Importing events for training to App ID 358" "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_load_data_performs_initial_load_requires_DATABASE_URL()
{
  unset DATABASE_URL
  cat > "$appDataDir/initial-events.json" <<'HEREDOC'
{"event":"$set","entity":"test","entityId":"0"}
HEREDOC

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-load-data
  assertEquals 3 ${rtrn}
  assertContains "DATABASE_URL is required" "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_load_data_performs_initial_load_requires_PIO_EVENTSERVER_APP_NAME()
{
  export DATABASE_URL=postgres://pio:pio@postgres:5432/pio
  cat > "$appDataDir/initial-events.json" <<'HEREDOC'
{"event":"$set","entity":"test","entityId":"0"}
HEREDOC

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-load-data
  assertEquals 3 ${rtrn}
  assertContains "PIO_EVENTSERVER_APP_NAME is required" "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_load_data_performs_initial_load_requires_PIO_EVENTSERVER_ACCESS_KEY()
{
  export DATABASE_URL=postgres://pio:pio@postgres:5432/pio
  export PIO_EVENTSERVER_APP_NAME=just-an-app
  cat > "$appDataDir/initial-events.json" <<'HEREDOC'
{"event":"$set","entity":"test","entityId":"0"}
HEREDOC
  cat > $pioCommandSpy <<'HEREDOC'
#!/bin/sh
if [ "$1" = "app" ] && [ "$2" = "show" ]
  then
  echo "Spy 'pio app'"
  echo "App does not exist"
  exit 1
else
  exit 1
fi
HEREDOC

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-load-data
  assertEquals 3 ${rtrn}
  assertContains "PIO_EVENTSERVER_ACCESS_KEY is required" "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_load_data_loads_initial()
{
  export DATABASE_URL=postgres://pio:pio@postgres:5432/pio
  export PIO_EVENTSERVER_APP_NAME=just-an-app
  export PIO_EVENTSERVER_ACCESS_KEY=12345
  cat > "$appDataDir/create-initial-events" <<HEREDOC
#!/bin/sh
echo '{"event":"$set","entity":"test","entityId":"0"}' > $BUILD_DIR/data/initial-events.json
echo 'did-create-events'
HEREDOC
  chmod +x "$appDataDir/create-initial-events"
  cat > $pioCommandSpy <<'HEREDOC'
#!/bin/sh
if [ "$1" = "app" ] && [ "$2" = "show" ]
  then
  echo "Spy 'pio app show'"
  echo "App does not exist"
  exit 1
elif [ "$1" = "app" ] && [ "$2" = "new" ]
  then
  echo "Spy 'pio app new'"
  echo "ID: 358"
elif [ "$1" = "import" ]
  then
  echo "Spy 'pio $@'"
  echo "Events imported"
else
  exit 1
fi
HEREDOC

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-load-data
  assertEquals 0 ${rtrn}
  assertContains "Importing events for training to App ID 358" "$(cat ${STD_OUT})"
  assertContains "did-create-events" "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_load_data_loads_initial_with_s3_sigv4()
{
  export DATABASE_URL=postgres://pio:pio@postgres:5432/pio
  export PIO_EVENTSERVER_APP_NAME=just-an-app
  export PIO_EVENTSERVER_ACCESS_KEY=12345
  export AWS_REGION=eu-central-1
  cat > "$appDataDir/create-initial-events" <<HEREDOC
#!/bin/sh
echo '{"event":"$set","entity":"test","entityId":"0"}' > $BUILD_DIR/data/initial-events.json
echo 'did-create-events'
HEREDOC
  chmod +x "$appDataDir/create-initial-events"
  cat > $pioCommandSpy <<'HEREDOC'
#!/bin/sh
if [ "$1" = "app" ] && [ "$2" = "show" ]
  then
  echo "Spy 'pio app show'"
  echo "App does not exist"
  exit 1
elif [ "$1" = "app" ] && [ "$2" = "new" ]
  then
  echo "Spy 'pio app new'"
  echo "ID: 358"
elif [ "$1" = "import" ]
  then
  echo "Spy 'pio $@'"
  echo "Events imported"
else
  exit 1
fi
HEREDOC

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-load-data
  assertEquals 0 ${rtrn}
  assertContains "Importing events for training to App ID 358" "$(cat ${STD_OUT})"
  assertContains "did-create-events" "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_load_data_loads_initial_requires_correct_batch_file()
{
  export DATABASE_URL=postgres://pio:pio@postgres:5432/pio
  export PIO_EVENTSERVER_APP_NAME=just-an-app
  export PIO_EVENTSERVER_ACCESS_KEY=12345
  cat > "$appDataDir/create-initial-events" <<'HEREDOC'
#!/bin/sh
echo 'did-create-events'
HEREDOC
  chmod +x "$appDataDir/create-initial-events"
  cat > $pioCommandSpy <<'HEREDOC'
#!/bin/sh
if [ "$1" = "app" ] && [ "$2" = "show" ]
  then
  echo "Spy 'pio app show'"
  echo "App does not exist"
  exit 1
elif [ "$1" = "app" ] && [ "$2" = "new" ]
  then
  echo "Spy 'pio app new'"
  echo "ID: 358"
elif [ "$1" = "import" ]
  then
  echo "Spy 'pio $@'"
  echo "Events imported"
else
  exit 1
fi
HEREDOC

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-load-data
  assertEquals 1 ${rtrn}
  assertContains "did not produce the required output" "$(cat ${STD_OUT})"
  assertContains "No such file" "$(cat ${STD_ERR})"
}

test_load_data_performs_sync()
{
  export DATABASE_URL=postgres://pio:pio@postgres:5432/pio
  export PIO_EVENTSERVER_APP_NAME=just-an-app
  export PIO_EVENTSERVER_ACCESS_KEY=12345
  cat > "$appDataDir/create-sync-events" <<HEREDOC
#!/bin/sh
echo '{"event":"$set","entity":"test","entityId":"0"}' > $BUILD_DIR/data/sync-events.json
echo 'events-did-sync'
HEREDOC
  chmod +x "$appDataDir/create-sync-events"
  cat > $pioCommandSpy <<'HEREDOC'
#!/bin/sh
if [ "$1" = "app" ] && [ "$2" = "show" ]
  then
  echo "Spy 'pio app show'"
  echo "ID: 358"
elif [ "$1" = "import" ]
  then
  echo "Spy 'pio $@'"
  echo "Events imported"
else
  exit 1
fi
HEREDOC

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-load-data
  assertEquals 0 ${rtrn}
  assertContains "Syncing events for training to App ID 358" "$(cat ${STD_OUT})"
  assertContains "events-did-sync" "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_load_data_performs_sync_with_s3_sigv4()
{
  export DATABASE_URL=postgres://pio:pio@postgres:5432/pio
  export PIO_EVENTSERVER_APP_NAME=just-an-app
  export PIO_EVENTSERVER_ACCESS_KEY=12345
  export AWS_REGION=eu-central-1
  cat > "$appDataDir/create-sync-events" <<HEREDOC
#!/bin/sh
echo '{"event":"$set","entity":"test","entityId":"0"}' > $BUILD_DIR/data/sync-events.json
echo 'events-did-sync'
HEREDOC
  chmod +x "$appDataDir/create-sync-events"
  cat > $pioCommandSpy <<'HEREDOC'
#!/bin/sh
if [ "$1" = "app" ] && [ "$2" = "show" ]
  then
  echo "Spy 'pio app show'"
  echo "ID: 358"
elif [ "$1" = "import" ]
  then
  echo "Spy 'pio $@'"
  echo "Events imported"
else
  exit 1
fi
HEREDOC

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-load-data
  assertEquals 0 ${rtrn}
  assertContains "Syncing events for training to App ID 358" "$(cat ${STD_OUT})"
  assertContains "-Dcom.amazonaws.services.s3.enableV4" "$(cat ${STD_OUT})"
  assertContains "events-did-sync" "$(cat ${STD_OUT})"
  assertEquals "" "$(cat ${STD_ERR})"
}

test_load_data_skips_sync_without_correct_batch_file()
{
  export DATABASE_URL=postgres://pio:pio@postgres:5432/pio
  export PIO_EVENTSERVER_APP_NAME=just-an-app
  export PIO_EVENTSERVER_ACCESS_KEY=12345
  cat > "$appDataDir/create-sync-events" <<'HEREDOC'
#!/bin/sh
echo 'events-did-sync'
HEREDOC
  chmod +x "$appDataDir/create-sync-events"
  cat > $pioCommandSpy <<'HEREDOC'
#!/bin/sh
if [ "$1" = "app" ] && [ "$2" = "show" ]
  then
  echo "Spy 'pio app show'"
  echo "ID: 358"
elif [ "$1" = "import" ]
  then
  echo "Spy 'pio $@'"
  echo "Events imported"
else
  exit 1
fi
HEREDOC

  capture ${BUILDPACK_HOME}/bin/engine/heroku-buildpack-pio-load-data
  assertEquals 0 ${rtrn}
  assertContains "did not produce the file" "$(cat ${STD_OUT})"
  assertContains "No such file" "$(cat ${STD_ERR})"
}