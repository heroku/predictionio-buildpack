package org.template.classification

import org.apache.spark.mllib.regression.LabeledPoint
import org.apache.spark.mllib.linalg.Vectors

import org.scalatest.FlatSpec
import org.scalatest.Matchers

class PreparatorTest
  extends FlatSpec with SharedSingletonContext with Matchers {

  val dataSource = Seq(
    LabeledPoint(0, Vectors.dense(1000, 10, 10)),
    LabeledPoint(1, Vectors.dense(10, 1000, 10)),
    LabeledPoint(2, Vectors.dense(10, 10, 1000))
  )

  "prepare" should "return synthetic features" in {
    val dataSourceRDD = sparkContext.parallelize(dataSource)
    val preparedData = new PreparedData(labeledPoints = dataSourceRDD)

    preparedData shouldBe a [PreparedData]
  }
}