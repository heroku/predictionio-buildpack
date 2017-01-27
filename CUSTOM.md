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
  1. [Create a PredictionIO app in the eventserver](#create-a-predictionio-app-in-the-eventserver)
  1. [Configure the Heroku app to use the eventserver](#configure-the-heroku-app-to-use-the-eventserver)
  1. [Update `engine.json`](#update-engine-json)
  1. [Import data](#import-data)
  1. [Deploy to Heroku](#deploy-to-heroku)
* [Training](#training)
  * [Automatic training](#automatic-training)
  * [Manual training](#manual-training)
* [Scale-up](#scale-up)
* [Retry release](#retry-release)
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

🏷 This buildpack should be used with engine templates for **PredictionIO 0.10**.

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
* bring your own [s3 bucket](https://aws.amazon.com/s3/) by manually setting the [`PIO_S3_*` config vars](#environment-variables).

⚠️ Note that with HDFS on Heroku, all filesystem path references must be absolute from `/` root, not relative or nested in User ID directory.

### Create a PredictionIO app in the eventserver

⚠️ **Not required for engines that exclusively use a custom data source.**

```bash
heroku run "pio app new $PIO_APP_NAME" -a $EVENTSERVER_NAME
```

* This returns an access key for the app; use it below in place of `$PIO_APP_ACCESS_KEY`.

### Configure the Heroku app to use the eventserver

⚠️ **Not required for engines that exclusively use a custom data source.**

Replace the Postgres ID & eventserver config values with those from above:

```bash
heroku addons:attach $POSTGRES_ADDON_ID
heroku config:set \
  PIO_EVENTSERVER_HOSTNAME=$EVENTSERVER_NAME.herokuapp.com \
  PIO_EVENTSERVER_PORT=80 \
  PIO_EVENTSERVER_ACCESS_KEY=$PIO_APP_ACCESS_KEY \
  PIO_EVENTSERVER_APP_NAME=$PIO_APP_NAME
```

* See [environment variables](#environment-variables) for config details.

### Update `engine.json`

⚠️ **Not required for engines that exclusively use a custom data source.**

Modify this file to make sure the `appName` parameter matches the app record [created in the eventserver](#generate-an-app-record-on-the-eventserver).

```json
  "datasource": {
    "params" : {
      "appName": "$PIO_APP_NAME"
    }
  }
```

* If the `appName` param is missing, you may need to [upgrade the template](https://predictionio.incubator.apache.org/resources/upgrade/).

### Import data

🚨 Mandatory: data is required for training to succeed and then to serve predictive queries.

This step will vary based on the engine. Typically, a command formatted like the following, should be run locally:

```bash
python ./data/import_eventserver.py \
  --url https://$EVENTSERVER_NAME.herokuapp.com \
  --access_key $PIO_APP_ACCESS_KEY
```

* check the engine's `data/` directory for exact naming & format.
* `pip install predictionio` may be required for the import script to run

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


## Training

### Automatic training

`pio train` will automatically run during [release-phase of the Heroku app](https://devcenter.heroku.com/articles/release-phase).

### Manual training

```bash
heroku run train

# You may need to revive the app from "crashed" state.
heroku restart
```

## Scale up

Once deployed, scale up the processes and config Spark to avoid memory issues. These are paid, [professional dyno types](https://devcenter.heroku.com/articles/dyno-types#available-dyno-types):

```bash
heroku ps:scale \
  web=1:Performance-M \
  release=0:Performance-L \
  train=0:Performance-L
```

## Retry release

When the release (`pio train`) fails due to memory constraints or other transient error, you may use the Heroku CLI [releases:retry plugin](https://github.com/heroku/heroku-releases-retry) to rerun the release without pushing a new deployment.


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

* `PIO_BUILD_SPARK_VERSION`
  * default `1.6.2`
  * supports `1.4.1`, `1.5.1`, `1.6.1`, & `1.6.2`
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
* `PIO_EVENTSERVER_HOSTNAME`
  * `$EVENTSERVER_NAME.herokuapp.com`
* `PIO_EVENTSERVER_PORT`
  * always `80` for Heroku apps
* `PIO_EVENTSERVER_APP_NAME` & `PIO_EVENTSERVER_ACCESS_KEY`
  * generated by running `pio app new $PIO_APP_NAME` on the eventserver
* `PIO_TRAIN_ON_RELEASE`
  * set `false` to disable automatic training
  * subsequent deploys will crash a deployed engine until it's retrained; use [manual training](#manual-training)
* `PIO_S3_BUCKET_NAME`, `PIO_S3_AWS_ACCESS_KEY_ID`, & `PIO_S3_AWS_SECRET_ACCESS_KEY`
  * configures a bucket to enable filesystem access

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

#### Fix for database connectivity with PredictionIO 0.9.5

`pio` commands that require DB access will need to have the driver specified as an argument (bug with PIO 0.9.5 + Spark 1.6.1):

```bash
pio $command -- --driver-class-path /app/lib/postgresql_jdbc.jar
```

