# [PredictionIO](https://predictionio.incubator.apache.org) classification engine for [Heroku](http://www.heroku.com) 

A machine learning classifier deployable to Heroku with the [PredictionIO buildpack](https://github.com/heroku/predictionio-buildpack).

[Spark's Random Forests algorithm](https://spark.apache.org/docs/1.6.2/mllib-ensembles.html) is used to predict a label using decision trees. See [A Visual Introduction to Machine Learning](http://www.r2d3.us/visual-intro-to-machine-learning-part-1/) to learn why decision trees are so effective.

Based on the [attribute-based classifier template](https://github.com/apache/incubator-predictionio-template-attribute-based-classifier) modified to use an [alternative algorithm](http://predictionio.incubator.apache.org/templates/classification/add-algorithm/). Originally this engine implemented [Spark's Naive Bayes algorithm](https://spark.apache.org/docs/1.6.2/mllib-naive-bayes.html). We soon switched to Random Forests to improve predictions by correlating attributes, a well-known weakness of Naive Bayes. The Bayes algorithm is still available in the engine source.


## Demo Story 🐸

This engine demonstrates prediction of the best fitting **service plan** for a **mobile phone user** based on their **voice, data, and text usage**. The model is trained with a small, example data set.

The **service plans** labelled in the [included training data](data/) are:

* `0` **Low Usage**: no services significantly utilized
* `1` **More Voice**: expanded talk time to 1000 minutes
* `2` **More Data**: expanded transfer quota to 1000 megabytes
* `3` **More Texts**: expanded SMS to 1000 messages
* `4` **Voice + Data**: expanded talk time & transfer quota
* `5` **Data + Text**: expanded transfer quota & SMS
* `6` **Voice + Text**: expanded talk time & SMS
* `7` **More Everything**: all services used evenly


## How To 📚

✏️ Throughout this document, code terms that start with `$` represent a value (shell variable) that should be replaced with a customized value, e.g `$EVENTSERVER_NAME`, `$ENGINE_NAME`, `$POSTGRES_ADDON_ID`…

### Deploy to Heroku

Please follow steps in order.

1. [Requirements](#1-requirements)
1. [Eventserver](#2-eventserver)
  1. [Create the eventserver](#create-the-eventserver)
  1. [Deploy the eventserver](#deploy-the-eventserver)
1. [Classification engine](#3-classification-engine)
  1. [Create the engine](#create-the-engine)
  1. [Connect the engine with the eventserver](#connect-the-engine-with-the-eventserver)
  1. [Import data](#import-data)
  1. [Deploy the engine](#deploy-the-engine)
  1. [Scale-up](#scale-up)
  1. [Retry release](#retry-release)

### Usage

Once deployed, how to work with the engine.

* 🎯 [Query for predictions](#query-for-predictions)
* [Diagnostics](#diagnostics)


# Deploy to Heroku 🚀

## 1. Requirements

* [Heroku account](https://signup.heroku.com)
* [Heroku CLI](https://toolbelt.heroku.com), command-line tools
* [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

## 2. Eventserver

### Create the eventserver

⚠️ **An eventserver may host data for multiple engines.** If you already have one provisioned, you may skip to the [engine](#3-classification-engine).

```bash
git clone \
  https://github.com/heroku/predictionio-buildpack.git \
  pio-eventserver

cd pio-eventserver

heroku create $EVENTSERVER_NAME
heroku addons:create heroku-postgresql:hobby-dev
# Note the buildpacks differ for eventserver & engine (below)
heroku buildpacks:add -i 1 https://github.com/heroku/predictionio-buildpack.git
heroku buildpacks:add -i 2 heroku/scala
```

### Deploy the eventserver

We delay deployment until the database is ready.

```bash
heroku pg:wait && git push heroku master
```


## 3. Classification Engine

### Create the engine

```bash
git clone \
  https://github.com/heroku/predictionio-engine-classification.git \
  pio-engine-classi

cd pio-engine-classi

heroku create $ENGINE_NAME
# Note the buildpacks differ for eventserver (above) & engine
heroku buildpacks:add -i 1 https://github.com/heroku/heroku-buildpack-jvm-common.git
heroku buildpacks:add -i 2 https://github.com/heroku/predictionio-buildpack.git
```

### Connect the engine with the eventserver

First, collect a few configuration values.

#### Get the eventserver's database add-on ID

```bash
heroku addons:info heroku-postgresql --app $EVENTSERVER_NAME
#
# Use the returned Postgres add-on ID
# to attach it to the engine.
# Example: `postgresql-aerodynamic-00000`
#
heroku addons:attach $POSTGRES_ADDON_ID --app $ENGINE_NAME
```

#### Get an access key for this engine's data

```bash
heroku run 'pio app new classi' --app $EVENTSERVER_NAME
#
# Use the returned access key for `$PIO_APP_ACCESS_KEY`
#
heroku config:set \
  PIO_EVENTSERVER_HOSTNAME=$EVENTSERVER_NAME.herokuapp.com \
  PIO_EVENTSERVER_PORT=80 \
  PIO_EVENTSERVER_ACCESS_KEY=$PIO_APP_ACCESS_KEY \
  PIO_EVENTSERVER_APP_NAME=classi
```

### Import data

Initial training data is automatically imported from [`data/initial-events.json`](data/initial-events.json). (This used to be a manual step that we automated using Heroku's [release phase](https://devcenter.heroku.com/articles/release-phase).)

### Deploy the engine

```bash
git push heroku master

# Follow the logs to see training 
# and then start-up of the engine.
#
heroku logs -t --app $ENGINE_NAME
```

⚠️ **Initial deploy will probably fail due to memory constraints.** Proceed to scale up.

## Scale up

Once deployed, scale up the processes and config Spark to avoid memory issues. These are paid, [professional dyno types](https://devcenter.heroku.com/articles/dyno-types#available-dyno-types):

```bash
heroku ps:scale \
  web=1:Standard-2X \
  release=0:Performance-L \
  train=0:Performance-L \
  --app $ENGINE_NAME
```

## Retry release

When the release (`pio train`) fails due to memory constraints or other transient error, you may use the Heroku CLI [releases:retry plugin](https://github.com/heroku/heroku-releases-retry) to rerun the release without pushing a new deployment.


# Usage ⌨️

## Query for predictions

Once deployment completes, the engine is ready to predict the best fitting **service plan** for a **mobile phone user** based on their **voice, data, and text usage**.

Submit queries containing these three user attributes to get predictions using [Spark's Random Forests algorithm](https://spark.apache.org/docs/1.6.2/mllib-ensembles.html):

```bash
# Fits low usage, `0`
curl -X "POST" "https://$ENGINE_NAME.herokuapp.com/queries.json" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d "{\"voice_usage\":12,\"data_usage\":0,\"text_usage\":4}"

# Fits more voice, `1`
curl -X "POST" "https://$ENGINE_NAME.herokuapp.com/queries.json" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d "{\"voice_usage\":480,\"data_usage\":0,\"text_usage\":121}"

# Fits more data, `2`
curl -X "POST" "https://$ENGINE_NAME.herokuapp.com/queries.json" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d "{\"voice_usage\":25,\"data_usage\":1000,\"text_usage\":80}"

#Fits more texts, `3`
curl -X "POST" "https://$ENGINE_NAME.herokuapp.com/queries.json" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d "{\"voice_usage\":5,\"data_usage\":80,\"text_usage\":1000}"

#Extreme voice & data, `4`
curl -X "POST" "https://$ENGINE_NAME.herokuapp.com/queries.json" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d "{\"voice_usage\":450,\"data_usage\":1104,\"text_usage\":43}"

#Extreme data & text, `5`
curl -X "POST" "https://$ENGINE_NAME.herokuapp.com/queries.json" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d "{\"voice_usage\":24,\"data_usage\":770,\"text_usage\":482}"

#Extreme voice & text, `6`
curl -X "POST" "https://$ENGINE_NAME.herokuapp.com/queries.json" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d "{\"voice_usage\":450,\"data_usage\":80,\"text_usage\":332}"

#Everything equal / balanced usage, `7`
curl -X "POST" "https://$ENGINE_NAME.herokuapp.com/queries.json" \
     -H "Content-Type: application/json; charset=utf-8" \
     -d "{\"voice_usage\":450,\"data_usage\":432,\"text_usage\":390}"
```

For a production model, more aspects of a user account and their correlations might be taken into consideration, including: account type (individual, business, or family), frequency of roaming, international usage, device type (smart phone or feature phone), age of device, etc.


## Diagnostics

If you hit any snags with the engine serving queries, check the logs:

```bash
heroku logs -t --app $ENGINE_NAME
```

If errors are occuring, sometimes a restart will help:

```bash
heroku restart --app $ENGINE_NAME
```
