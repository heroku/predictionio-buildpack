package org.template.classification

import org.apache.spark.mllib.regression.LabeledPoint
import org.apache.spark.mllib.linalg.Vectors
import org.apache.spark.mllib.classification.NaiveBayesModel

import org.scalatest.FlatSpec
import org.scalatest.Matchers

class NaiveBayesAlgorithmTest
  extends FlatSpec with SharedSingletonContext with Matchers {

  val params = AlgorithmParams(lambda = 10)
  val algorithm = new NaiveBayesAlgorithm(params)

  val dataSource = Seq(
    LabeledPoint(0, Vectors.dense(1000, 10, 10)),
    LabeledPoint(1, Vectors.dense(10, 1000, 10)),
    LabeledPoint(2, Vectors.dense(10, 10, 1000))
  )

  "train" should "return NaiveBayes model" in {
    val dataSourceRDD = sparkContext.parallelize(dataSource)
    val preparedData = new PreparedData(labeledPoints = dataSourceRDD)
    val model = algorithm.train(sparkContext, preparedData)
    model shouldBe a [NaiveBayesModel]
  }
}