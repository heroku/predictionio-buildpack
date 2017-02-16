# [Heroku buildpack](https://devcenter.heroku.com/articles/buildpacks) for PredictionIO

Enables data scientists and developers to deploy custom machine learning services created with [PredictionIO](https://predictionio.incubator.apache.org).

This buildpack is part of an exploration into utilizing the [Heroku developer experience](https://www.heroku.com/dx) to simplify data science operations. When considering this proof-of-concept technology, please note its [current limitations](#limitations). We'd love to hear from you. [Open issues on this repo](https://github.com/heroku/predictionio-buildpack/issues) with feedback and questions.

## Engines

Supports engines created for **PredictionIO 0.10.0-incubating**.

* [Classification demo](https://github.com/heroku/predictionio-engine-classification) presented at [Dreamforce 2016 "Exploring Machine Learning On Heroku"](https://www.salesforce.com/video/297129/)
* [Template Gallery](https://predictionio.incubator.apache.org/gallery/template-gallery/) offers starting-points for many use-cases.

🐸 **[How to deploy a template or custom engine](CUSTOM.md#engine)**

## Architecture

This buildpack transforms the [Scala](http://www.scala-lang.org) source-code of a PredictionIO engine into a [Heroku app](https://devcenter.heroku.com/articles/how-heroku-works).

![Diagram of Deployment to Heroku Common Runtime](http://marsikai.s3.amazonaws.com/predictionio-buildpack-arch-01.png)

The events data can be stored in:

* **PredictionIO Eventserver** backed by Heroku PostgreSQL
  * directly compatible with most engine templates
* **custom data store** such as Heroku Connect with PostgreSQL or RDD/DataFrames stored in HDFS
  * requires a custom implementaion of `DataSource.scala`.

## Limitations

### Memory

This buildpack automatically trains the predictive model during [release phase](https://devcenter.heroku.com/articles/release-phase), which runs in a [one-off dyno](https://devcenter.heroku.com/articles/dynos). That dyno's memory capacity is a limiting factor at this time. Only [Performance dynos](https://www.heroku.com/pricing) with 2.5GB or 14GB RAM provide reasonable utility. This limitation can be worked-around by pointing the engine at an existing Spark cluster. See: [customizing environment variables, `PIO_SPARK_OPTS` & `PIO_TRAIN_SPARK_OPTS`](CUSTOM.md#environment-variables).

### No Private Network

[Spark clusters](https://spark.apache.org/docs/1.6.2/spark-standalone.html) require a private network, so they cannot be deployed in the [Common Runtime](https://devcenter.heroku.com/articles/dyno-runtime). To operate in the Common Runtime this buildpack executes Spark as a sub-process (i.e. [`--master local`](https://spark.apache.org/docs/1.6.2/#running-the-examples-and-shell)) within [one-off and web dynos](https://devcenter.heroku.com/articles/dynos). This buildpack does support executing jobs on an existing Spark cluster. See: [customizing environment variables, `PIO_SPARK_OPTS` & `PIO_TRAIN_SPARK_OPTS`](CUSTOM.md#environment-variables).

### Additional Service Dependencies

Engines may require [Elasticsearch](https://predictionio.incubator.apache.org/system/) [ES] which is not currently supported on Heroku (see [this pull request](https://github.com/heroku/predictionio-buildpack/pull/16)). [Heroku Postgres](https://www.heroku.com/postgres) is the default storage repository, so this does not effect many engines. *There is [work underway](https://github.com/apache/incubator-predictionio/pull/336) in the PredictionIO project to support ES by upgrading to ES 5.x and migrating to pure-REST interface.*

### Stateless Builds

PredictionIO 0.10.0-incubating requires a database connection during the build phase. While this works fine in the [Common Runtime](https://devcenter.heroku.com/articles/dyno-runtime), it is not compatible with [Private Databases](https://devcenter.heroku.com/articles/heroku-postgres-and-private-spaces). *There is [work underway](https://github.com/apache/incubator-predictionio/pull/328) in the PredictionIO project to solve this problem by making `pio build` a stateless command.*

## Testing

[Tests](test/) are composed and run using [heroku-buildpack-testrunner](https://github.com/heroku/heroku-buildpack-testrunner). Engine test cases are staged in the [`test/fixtures/`](test/fixtures/).

Setup [testrunner with Docker](https://github.com/heroku/heroku-buildpack-testrunner#docker-usage), then run tests with:

```bash
docker run -it \
  -v path/to/this-buildpack:/app/buildpack:ro
  -v ~/magic_curl_cache:/tmp/magic_curl_cache heroku/buildpack-testrunner
```
