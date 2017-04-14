#!/usr/bin/env bash

# Check for Elasticsearch config var
if [ "${PIO_ELASTICSEARCH_URL:-}" ]
  then
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

  export PIO_ELASTICSEARCH_SCHEMES=$scheme
  export PIO_ELASTICSEARCH_HOSTS=$host
  export PIO_ELASTICSEARCH_PORTS=$port
  export PIO_ELASTICSEARCH_USERNAME=$user
  export PIO_ELASTICSEARCH_PASSWORD=$pass
fi