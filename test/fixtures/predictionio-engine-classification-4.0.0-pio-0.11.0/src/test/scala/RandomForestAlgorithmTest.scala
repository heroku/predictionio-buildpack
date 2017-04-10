package org.template.classification

import org.apache.spark.mllib.regression.LabeledPoint
import org.apache.spark.mllib.linalg.Vectors
import org.apache.spark.mllib.tree.RandomForest
import org.apache.spark.mllib.tree.model.RandomForestModel

import org.scalatest.FlatSpec
import org.scalatest.Matchers

class RandomForestAlgorithmTest
  extends FlatSpec with SharedSingletonContext with Matchers {

  val params = RandomForestAlgorithmParams(
    numClasses = 7,
    numTrees = 12,
    featureSubsetStrategy = "auto",
    impurity = "gini",
    maxDepth = 4,
    maxBins = 100)
  val algorithm = new RandomForestAlgorithm(params)

  val dataSource = Seq(
    LabeledPoint(0, Vectors.dense(1000, 10, 10)),
    LabeledPoint(1, Vectors.dense(10, 1000, 10)),
    LabeledPoint(2, Vectors.dense(10, 10, 1000))
  )

  "train" should "return RandomForest model" in {
    val dataSourceRDD = sparkContext.parallelize(dataSource)
    val preparedData = new PreparedData(labeledPoints = dataSourceRDD)
    val model = algorithm.train(sparkContext, preparedData)
    model shouldBe a [RandomForestModel]
  }
}