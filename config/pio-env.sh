#!/usr/bin/env bash

# 12-factor config, using environment variables for dynamic values

# PredictionIO Main Configuration
#
# This section controls core behavior of PredictionIO. It is very likely that
# you need to change these to fit your site.

# SPARK_HOME: Apache Spark is a hard dependency and must be configured.
# Must match $spark_dist_dir in bin.compile
SPARK_HOME=$PIO_HOME/vendors/spark-hadoop
SPARK_LOCAL_IP="${HEROKU_PRIVATE_IP:-127.0.0.1}"
SPARK_PUBLIC_DNS="${HEROKU_DNS_DYNO_NAME:-}"

POSTGRES_JDBC_DRIVER=$PIO_HOME/lib/postgresql_jdbc.jar

# ES_CONF_DIR: You must configure this if you have advanced configuration for
#              your Elasticsearch setup.
ES_CONF_DIR=$PIO_HOME/conf

# HADOOP_CONF_DIR: You must configure this if you intend to run PredictionIO
#                  with Hadoop 2.
HADOOP_CONF_DIR=$PIO_HOME/conf

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
if [ "${PIO_ELASTICSEARCH_URL:-}" ]
    then
    PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=ELASTICSEARCH
else
    PIO_STORAGE_REPOSITORIES_METADATA_SOURCE=PGSQL
fi
PIO_STORAGE_REPOSITORIES_EVENTDATA_NAME=pio_event
PIO_STORAGE_REPOSITORIES_EVENTDATA_SOURCE=PGSQL
PIO_STORAGE_REPOSITORIES_MODELDATA_NAME=pio_model
PIO_STORAGE_REPOSITORIES_MODELDATA_SOURCE=PGSQL
PIO_STORAGE_SOURCES_PGSQL_TYPE=jdbc

# Transform Postgres connetion URL (Heroku config var) to PIO vars.
if [ -z "${DATABASE_URL}" ]; then
    PIO_STORAGE_SOURCES_PGSQL_URL=jdbc:postgresql://localhost:5432/pio
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

    # extract the host
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
PIO_STORAGE_SOURCES_ELASTICSEARCH_HOME=$PIO_HOME/vendors/elasticsearch
# Check for Elasticsearch config var
if [ -z "${PIO_ELASTICSEARCH_URL}" ]; then
    PIO_STORAGE_SOURCES_ELASTICSEARCH_SCHEMES=http
    PIO_STORAGE_SOURCES_ELASTICSEARCH_HOSTS=localhost
    PIO_STORAGE_SOURCES_ELASTICSEARCH_PORTS=9200
else
    # from: http://stackoverflow.com/a/17287984/77409
    # extract the protocol
    proto="`echo $PIO_ELASTICSEARCH_URL | grep '://' | sed -e's,^\(.*://\).*,\1,g'`"
    scheme="`echo $proto | rev | cut -c 4- | rev`"
    # remove the protocol
    url=`echo $PIO_ELASTICSEARCH_URL | sed -e s,$proto,,g`

    # extract the user and password (if any)
    userpass="`echo $url | grep @ | cut -d@ -f1`"
    pass=`echo $userpass | grep : | cut -d: -f2`
    if [ -n "$pass" ]; then
        user=`echo $userpass | grep : | cut -d: -f1`
    else
        user=$userpass
    fi

    # extract the host
    hostport=`echo $url | sed -e s,$userpass@,,g | cut -d/ -f1`
    port=`echo $hostport | grep : | cut -d: -f2`
    if [ -n "$port" ]; then
        host=`echo $hostport | grep : | cut -d: -f1`
    else
        host=$hostport
    fi

    # set explicit port for SSL
    if [ -z "$port" ] && [ "$scheme" = "https" ]; then
        port=443
    else
        port=9200
    fi

    PIO_STORAGE_SOURCES_ELASTICSEARCH_SCHEMES=$scheme
    PIO_STORAGE_SOURCES_ELASTICSEARCH_HOSTS=$host
    PIO_STORAGE_SOURCES_ELASTICSEARCH_PORTS=$port
    PIO_STORAGE_SOURCES_ELASTICSEARCH_USERNAME=$user
    PIO_STORAGE_SOURCES_ELASTICSEARCH_PASSWORD=$pass
fi
