package org.template.classification

import org.apache.spark.mllib.linalg.Vectors
import org.apache.spark.mllib.linalg.Vector

object SyntheticFeatures {

  // Synthesize averages for feature combinations.
  // Three features become seven:
  // f1, f2, f3, (f1+f2)/2, (f2+f3)/2, (f3+f1)/2, (f1+f2+f3)/3
  // These are averages of each pair and all three.
  def transform(vector:Vector):Vector = {
    val realFeatures: Array[Double] = vector.toArray

    var synthFeatures: Array[Double] = Array()
    var sumRealFeatures:Double = 0
    var i = 0
    var v:Double = 0

    v = realFeatures.apply(0)
    sumRealFeatures = sumRealFeatures + v
    synthFeatures = synthFeatures :+ (v + realFeatures.apply(1))/2

    v = realFeatures.apply(1)
    sumRealFeatures = sumRealFeatures + v
    synthFeatures = synthFeatures :+ (v + realFeatures.apply(2))/2

    v = realFeatures.apply(2)
    sumRealFeatures = sumRealFeatures + v
    synthFeatures = synthFeatures :+ (v + realFeatures.apply(0))/2

    // average of all features
    synthFeatures = synthFeatures :+ sumRealFeatures/3

    Vectors.dense(realFeatures ++ synthFeatures)
  }

}
