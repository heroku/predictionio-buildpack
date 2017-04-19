# Deploy [PredictionIO](http://predictionio.incubator.apache.org) to Heroku with a template or custom engine

👓 Requires intermediate technical skills working with PredictionIO.

🍎 For an simpler demo of PredictionIO, try the [example Predictive Classification app](https://github.com/heroku/predictionio-engine-classification).

🗺 See the [buildpack README](README.md) for an overview of the tools used in these docs.


## Docs 📚

✏️ Throughout this document, code terms that start with `$` represent a value (shell variable) that should be replaced with a customized value, e.g `$EVENTSERVER_NAME`, `$ENGINE_NAME`, `$POSTGRES_ADDON_ID`…

Please, follow the steps in the order documented.

* [Eventserver](#eventserver)
  1. [Create the eventserver](#create-the-eventserver)
  1. [Deploy the eventserver](#deploy-the-eventserver)
* [Engine](#engine)
  1. [Create an engine](#create-an-engine)
     * [Optional Persistent Filesystem](#optional-persistent-filesystem)
  1. [Create a Heroku app for the engine](#create-a-heroku-app-for-the-engine)
  1. [Configure the Heroku app to use the eventserver](#configure-the-heroku-app-to-use-the-eventserver)
  1. [Update source configs](#update-source-configs)
     1. [`template.json`](#update-template-json)
     1. [`build.sbt`](#update-build-sbt)
     1. [`engine.json`](#update-engine-json)
  1. [Import data](#import-data)
  1. [Deploy to Heroku](#deploy-to-heroku)
     * [Scale-up](#scale-up)
     * [Retry release](#retry-release)
* [Training](#training)
  * [Automatic training](#automatic-training)
  * [Manual training](#manual-training)
* [Evaluation](#evaluation)
  1. [Changes required for evaluation](#changes-required-for-evaluation)
  1. [Perform evaluation](#perform-evaluation)
  1. [Re-deploy best parameters](#re-deploy-best-parameters)
* [Configuration](#configuration)
  * [Environment variables](#environment-variables)
* [Running commands](#running-commands)


## Eventserver

### Create the eventserver

⚠️ **An eventserver may host data for multiple engines.** If you already have one provisioned, you may skip to the [engine](#engine).

⚠️ **Not required for engines that exclusively use a custom data source.**

```bash
git clone https://github.com/heroku/predictionio-buildpack.git pio-eventserver
cd pio-eventserver

heroku create $EVENTSERVER_NAME
heroku addons:create heroku-postgresql:hobby-dev
# Note the buildpacks differ for eventserver & engine (below)
heroku buildpacks:add -i 1 https://github.com/heroku/predictionio-buildpack.git
heroku buildpacks:add -i 2 heroku/scala
```

* Note the Postgres add-on identifier, e.g. `postgresql-aerodynamic-00000`; use it below in place of `$POSTGRES_ADDON_ID`
* You may want to specify `heroku-postgresql:standard-0` instead, because the free `hobby-dev` database is limited to 10,000 records.

### Deploy the eventserver

We delay deployment until the database is ready.

```bash
heroku pg:wait && git push heroku master
```


## Engine

Select an engine from the [gallery](https://predictionio.incubator.apache.org/gallery/template-gallery/). Download a `.tar.gz` from Github and open/expand it on your local computer.

🏷 This buildpack should be used with engine templates for **PredictionIO 0.11**.

### Create an engine

`cd` into the engine's directory, and ensure it is a git repo:

```bash
git init
```

### Create a Heroku app for the engine

```bash
heroku create $ENGINE_NAME
# Note the buildpacks differ for eventserver (above) & engine
heroku buildpacks:add -i 1 https://github.com/heroku/heroku-buildpack-jvm-common.git
heroku buildpacks:add -i 2 https://github.com/heroku/predictionio-buildpack.git
```

### Optional Persistent Filesystem

👓 Heroku dynos have an [ephemeral filesystem](https://devcenter.heroku.com/articles/dynos#ephemeral-filesystem).

For engines that require filesystem persistence, this buildpack supports [HDFS](https://en.wikipedia.org/wiki/Apache_Hadoop#HDFS) on [Amazon S3](https://aws.amazon.com/s3/).

To enable, either:

* use the [S3 Add-on](https://devcenter.heroku.com/articles/bucketeer) ($5/month minimum cost)

  ```bash
  heroku addons:create bucketeer --as PIO_S3
  ```
* bring your own [s3 bucket](https://aws.amazon.com/s3/) by manually setting the [config vars](#environment-variables)
  * `PIO_S3_BUCKET_NAME`
  * `PIO_S3_AWS_ACCESS_KEY_ID`
  * `PIO_S3_AWS_SECRET_ACCESS_KEY`

⚠️ Note that with HDFS on Heroku, all filesystem path references must be absolute from `/` root, not relative or nested in User ID directory.

### Configure the Heroku app to use the eventserver

⚠️ **Not required for engines that exclusively use a custom data source.**

Replace the Postgres ID & eventserver config values with those from above:

```bash
heroku addons:attach $POSTGRES_ADDON_ID

heroku config:set PIO_EVENTSERVER_APP_NAME=$PIO_APP_NAME
# must match `appName` in engine.json & eventserver
```

* See [environment variables](#environment-variables) for config details.

### Update source configs

#### `template.json`

The version of PredictionIO used for deployment is based in the value in this file:

```json
  "pio": {
    "version" : {
      "min": "0.11.0-incubating"
    }
  }
```

#### `build.sbt`

The Scala built tool config must be updated with Scala, PredictionIO, & Spark versions:

```scala
scalaVersion := "2.11.8"

organization := "org.apache.predictionio"

libraryDependencies ++= Seq(
  "org.apache.predictionio" %% "apache-predictionio-core" % "0.11.0-incubating" % "provided",
  "org.apache.spark"        %% "spark-core"               % "2.1.0" % "provided",
  "org.apache.spark"        %% "spark-mllib"              % "2.1.0" % "provided")
```

#### `engine.json`

Update so the `appName` parameter matches the [value set for `PIO_EVENTSERVER_APP_NAME`](#configure-the-heroku-app-to-use-the-eventserver).

```json
  "datasource": {
    "params" : {
      "appName": "$PIO_EVENTSERVER_APP_NAME"
    }
  }
```

⭐️  **A better alternative** is to delete the `"appName"` param from `engine.json`, and then use the environment variable value `sys.env("PIO_EVENTSERVER_APP_NAME")` in the engine source code.

### Import data

🚨 **Mandatory: Data is required.** The first time an engine is deployed, it requires data for training.

⚠️  If `data/initial-events.json` already exists in the engine, then skip to [Deploy to Heroku](#deploy-to-heroku). This data will automatically be imported into the eventserver before training.

For production engines, use one of the following:

* **Auto-load JSON data to eventserver**
  * import event data automatically, the first time the engine is deployed to Heroku, before training
  * create the [batch input file](http://predictionio.incubator.apache.org/datacollection/batchimport/) `data/initial-events.json`
* **Custom data loader script**
  * use to generate `data/initial-events.json` instead of checking it into the source repo
  * commit an executable script at `data/create-initial-events`
    * ensure executable with `chmod +x data/create-initial-events`
  * must output the [batch input file](http://predictionio.incubator.apache.org/datacollection/batchimport/) `data/initial-events.json`
* **Custom, pre-existing data source**
  * implement the engine's `DataSource.scala` to use a pre-existing data store, instead of the eventserver
  * probably does not need automatic data loading by the PredictionIO engine, so ensure `data/initial-events.json` is not-present, deleted from the engine.

### Deploy to Heroku

```bash
git add .
git commit -m "Initial PIO engine"
git push heroku master

# Follow the logs to see training 
# and then start-up of the engine.
#
heroku logs -t --app $ENGINE_NAME
```

⚠️ **Initial deploy will probably fail due to memory constraints.** To fix, [scale up](#scale-up) and [retry the release](#retry-release).

#### Scale up

Once deployed, scale up the processes and config Spark to avoid memory issues. These are paid, [professional dyno types](https://devcenter.heroku.com/articles/dyno-types#available-dyno-types):

```bash
heroku ps:scale \
  web=1:Performance-M \
  release=0:Performance-L \
  train=0:Performance-L
```

#### Retry release

When the release (`pio train`) fails due to memory constraints or other transient error, you may use the Heroku CLI [releases:retry plugin](https://github.com/heroku/heroku-releases-retry) to rerun the release without pushing a new deployment.


## Training

### Automatic training

`pio train` will automatically run during [release-phase of the Heroku app](https://devcenter.heroku.com/articles/release-phase).

### Manual training

```bash
heroku run train

# You may need to revive the app from "crashed" state.
heroku restart
```

## Evaluation

PredictionIO provides an [Evaluation mode for engines](https://predictionio.incubator.apache.org/evaluation/), which uses cross-validation to help select optimum engine parameters.

⚠️ Only engines that contain `src/main/scala/Evaluation.scala` support Evaluation mode.

### Changes required for evaluation

To run evaluation on Heroku, ensure `src/main/scala/Evaluation.scala` references the engine's name through the environment. Check the source file to verify that `appName` is set to `sys.env("PIO_EVENTSERVER_APP_NAME")`. For example:

```scala
DataSourceParams(appName = sys.env("PIO_EVENTSERVER_APP_NAME"), evalK = Some(5))
```

♻️ If that change was made, then commit, deploy, & re-train before proceeding.

### Perform evaluation

Next, start a console & change to the engine's directory. This uses a paid, [professional dyno type](https://devcenter.heroku.com/articles/dyno-types#available-dyno-types):

```bash
heroku run bash --size Performance-L
$ cd pio-engine/
```

Then, start the process, specifying the evaluation & engine params classes from the `Evaluation.scala` source file. For example:

```bash
$ pio eval \
    org.template.classification.AccuracyEvaluation \
    org.template.classification.EngineParamsList  \
    -- $PIO_SPARK_OPTS
```

✏️ Memory parameters are set to fit the [dyno `--size`](https://devcenter.heroku.com/articles/dyno-types#available-dyno-types) set in the `heroku run` command.

### Re-deploy best parameters

Once `pio eval` completes, still in the Heroku console, copy the contents of `best.json`:

```bash
$ cat best.json
```

♻️ Paste into your local `engine.json`, commit, & deploy.


## Configuration

### Environment variables

Engine deployments honor the following config vars:

* `DATABASE_URL` & `PIO_POSTGRES_OPTIONAL_SSL`
  * automatically set by [Heroku PostgreSQL](https://elements.heroku.com/addons/heroku-postgresql)
  * defaults to `postgres://pio:pio@locahost:5432/pio`
  * when testing locally, set `PIO_POSTGRES_OPTIONAL_SSL=true` to avoid **The server does not support SSL** errors
* `PIO_VERBOSE`
  * set `PIO_VERBOSE=true` for detailed build logs
* `PIO_MAVEN_REPO`
  * add a Maven repository URL to search when installing deps from engine's `build.sbt`
  * useful for testing pre-release packages
* `PREDICTIONIO_DIST_URL`
  * defaults to a PredictionIO distribution version based on `pio.version.min` in **template.json**
  * use a custom distribution by setting its fetch URL:

    ```bash
    heroku config:set PREDICTIONIO_DIST_URL=https://marsikai.s3.amazonaws.com/PredictionIO-0.10.0-incubating.tar.gz
    ```
* `PIO_OPTS`
  * options passed as `pio $opts`
  * see: [`pio` command reference](https://predictionio.incubator.apache.org/cli/)
  * example:

    ```bash
    heroku config:set PIO_OPTS='--variant best.json'
    ```
* `PIO_SPARK_OPTS` & `PIO_TRAIN_SPARK_OPTS`
  * **deploy** & **training** options passed through to `spark-submit $opts`
  * see: [`spark-submit` reference](http://spark.apache.org/docs/1.6.1/submitting-applications.html)
  * example, overriding the automatic (fit-to-dyno) Spark memory settings:

    ```bash
    heroku config:set \
      PIO_SPARK_OPTS='--executor-memory 1536m --driver-memory 1g' \
      PIO_TRAIN_SPARK_OPTS='--executor-memory 10g --driver-memory 4g'
    ```
  * example, using an existing Spark cluster (deploying a cluster is outside the scope of the buildpack):

    ```bash
    heroku config:set \
      PIO_TRAIN_SPARK_OPTS='--master spark://my-master.example.com:7077' \
      PIO_SPARK_OPTS='--master spark://my-master.example.com:7077'
    ```
  * note this additional constraint of Spark pass-through args,  
    `spark.driver.extraJavaOptions` is silently ignored:

    ```bash
    # Options are silently dropped when set through `--conf`.
    # Bad example; don't use this:
    PIO_SPARK_OPTS="--conf 'spark.driver.extraJavaOptions=-Dcom.amazonaws.services.s3.enableV4'"

    # Instead, pass them using `--driver-java-options`.
    # Good example; do this:
    PIO_SPARK_OPTS="--driver-java-options '-Dcom.amazonaws.services.s3.enableV4'"
    ```
* `PIO_ENABLE_FEEDBACK`
  * set `PIO_ENABLE_FEEDBACK=true` to enable feedback loop; auto-generation of historical prediction events for analysis of engine performance
  * requires the `PIO_EVENTSERVER_*` vars to be configured
* `PIO_EVENTSERVER_HOSTNAME` & `PIO_EVENTSERVER_PORT`
  * `$EVENTSERVER_NAME.herokuapp.com` & `443` (default) for Heroku apps' HTTPS interface
* `PIO_EVENTSERVER_APP_NAME` & `PIO_EVENTSERVER_ACCESS_KEY`
  * may be generated by running `pio app new $PIO_APP_NAME` on the eventserver
* `PIO_TRAIN_ON_RELEASE`
  * set `false` to disable automatic training
  * subsequent deploys may crash a deployed engine until it's retrained
  * use [manual training](#manual-training)
* `PIO_S3_BUCKET_NAME`, `PIO_S3_AWS_ACCESS_KEY_ID`, & `PIO_S3_AWS_SECRET_ACCESS_KEY`
  * configures a bucket to enable filesystem access
* `AWS_REGION`
  * when connecting to S3 in region other than US, the region name must be specified to enable signature v4.
* `PIO_ELASTICSEARCH_URL`
  * when set, activates [Elasticsearch](https://www.elastic.co/products/elasticsearch) as the [metadata store](http://predictionio.incubator.apache.org/system/anotherdatastore/)
  * Elasticsearch version 5.x is supported
  * use an [add-on](https://elements.heroku.com/search/addons?q=elasticsearch):

    ```bash
    heroku addons:create bonsai --version 5.1 --as PIO_ELASTICSEARCH
    ```


## Running commands

#### To run directly with Heroku CLI

```bash
heroku run pio $command
```

#### Useful commands

Check engine status:

```bash
heroku run pio status
```

