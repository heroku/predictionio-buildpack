#!/usr/bin/env bash

# 12-factor config, using environment variables for dynamic values

# PredictionIO Main Configuration
#
# This section controls core behavior of PredictionIO. It is very likely that
# you need to change these to fit your site.

# SPARK_HOME: Apache Spark is a hard dependency and must be configured.
# Must match $spark_dist_dir in bin.compile
SPARK_HOME=/app/pio-engine/PredictionIO-dist/vendors/spark-hadoop
SPARK_LOCAL_IP="${HEROKU_PRIVATE_IP:-}"
SPARK_PUBLIC_DNS="${HEROKU_DNS_DYNO_NAME:-}"

if [ -e "/app/.heroku/.is_old_predictionio" ]
then
  POSTGRES_JDBC_DRIVER=/app/lib/postgresql_jdbc.jar
fi

# ES_CONF_DIR: You must configure this if you have advanced configuration for
#              your Elasticsearch setup.
ES_CONF_DIR=/app/pio-engine/PredictionIO-dist/conf
PIO_STORAGE_SOURCES_ELASTICSEARCH_HOME=/app/pio-engine/PredictionIO-dist/vendors/elasticsearch

# HADOOP_CONF_DIR: You must configure this if you intend to run PredictionIO
#                  with Hadoop 2.
HADOOP_CONF_DIR=/app/pio-engine/PredictionIO-dist/conf

# HBASE_CONF_DIR: You must configure this if you intend to run PredictionIO
#                 with HBase on a remote cluster.
# HBASE_CONF_DIR=$PIO_HOME/vendors/hbase-1.0.0/conf

# Filesystem paths where PredictionIO uses as block storage.
PIO_FS_BASEDIR=$HOME/.pio_store
PIO_FS_ENGINESDIR=$PIO_FS_BASEDIR/engines
PIO_FS_TMPDIR=$PIO_FS_BASEDIR/tmp

# PredictionIO Storage Configuration
#
# This section controls programs that make use of PredictionIO's built-in
# storage facilities. Default values are shown below.
#
# For more information on storage configuration please refer to
# https://docs.prediction.io/system/anotherdatastore/

# Storage Repositories
PIO_STORAGE_REPOSITORIES_METADATA_NAME=pio_meta
PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=PGSQL
PIO_STORAGE_REPOSITORIES_EVENTDATA_NAME=pio_event
PIO_STORAGE_REPOSITORIES_EVENTDATA_SOURCE=PGSQL
PIO_STORAGE_REPOSITORIES_MODELDATA_NAME=pio_model
PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=PGSQL

# Configure JDBC PostgreSQL connection
PIO_STORAGE_SOURCES_PGSQL_TYPE=jdbc
# Transform Postgres connetion URL (Heroku config var) to PIO vars.
# Check for Heroku PostgreSQL config var
if [ -z "${DATABASE_URL}" ]; then
    PIO_STORAGE_SOURCES_PGSQL_URL=jdbc:postgresql://localhost/pio
    PIO_STORAGE_SOURCES_PGSQL_USERNAME=pio
    PIO_STORAGE_SOURCES_PGSQL_PASSWORD=pio
else
    # from: http://stackoverflow.com/a/17287984/77409
    # extract the protocol
    proto="`echo $DATABASE_URL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
    # remove the protocol
    url=`echo $DATABASE_URL | sed -e s,$proto,,g`

    # extract the user and password (if any)
    userpass="`echo $url | grep @ | cut -d@ -f1`"
    pass=`echo $userpass | grep : | cut -d: -f2`
    if [ -n "$pass" ]; then
        user=`echo $userpass | grep : | cut -d: -f1`
    else
        user=$userpass
    fi

    # extract the host -- updated
    hostport=`echo $url | sed -e s,$userpass@,,g | cut -d/ -f1`
    port=`echo $hostport | grep : | cut -d: -f2`
    if [ -n "$port" ]; then
        host=`echo $hostport | grep : | cut -d: -f1`
    else
        host=$hostport
    fi

    # extract the path (if any)
    path="`echo $url | grep / | cut -d/ -f2-`"

    if [ "$PIO_POSTGRES_OPTIONAL_SSL" = "true" ]
    then
        PIO_STORAGE_SOURCES_PGSQL_URL=jdbc:postgresql://$hostport/$path
    else
        PIO_STORAGE_SOURCES_PGSQL_URL=jdbc:postgresql://$hostport/$path?sslmode=require
    fi
    PIO_STORAGE_SOURCES_PGSQL_USERNAME=$user
    PIO_STORAGE_SOURCES_PGSQL_PASSWORD=$pass
fi

# Configure Elasticsearch connection
PIO_STORAGE_SOURCES_ELASTICSEARCH_TYPE=elasticsearch
# Check for Bonsai Elasticsearch config var
if [ -z "${BONSAI_URL}" ]; then
    PIO_STORAGE_SOURCES_ELASTICSEARCH_HOSTS=localhost
    PIO_STORAGE_SOURCES_ELASTICSEARCH_PORTS=9300
else
    # from: http://stackoverflow.com/a/17287984/77409
    # extract the protocol
    proto="`echo $BONSAI_URL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
    # remove the protocol
    url=`echo $BONSAI_URL | sed -e s,$proto,,g`

    # extract the user and password (if any)
    userpass="`echo $url | grep @ | cut -d@ -f1`"

    # extract the host -- updated
    hostport=`echo $url | sed -e s,$userpass@,,g | cut -d/ -f1`
    port=`echo $hostport | grep : | cut -d: -f2`
    if [ -n "$port" ]; then
        host=`echo $hostport | grep : | cut -d: -f1`
    else
        host=$hostport
    fi

    PIO_STORAGE_SOURCES_ELASTICSEARCH_HOSTS=$userpass@$host
    PIO_STORAGE_SOURCES_ELASTICSEARCH_PORTS=$port
fi
