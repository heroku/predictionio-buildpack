package org.template.classification

import org.apache.spark.mllib.linalg.Vectors

import org.scalatest.FlatSpec
import org.scalatest.Matchers

class SyntheticFeaturesTest
  extends FlatSpec with Matchers {

  "transform" should "return synthetic features" in {
    val vector = Vectors.dense(1000, 10, 10)
    val expectedVector = Vectors.dense(1000, 10, 10, 505, 10, 505, 340)

    val synthVector = SyntheticFeatures.transform(vector)
    synthVector should equal(expectedVector)
  }
}