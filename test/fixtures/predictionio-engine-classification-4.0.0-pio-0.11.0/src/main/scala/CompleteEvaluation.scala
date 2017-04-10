package org.template.classification

import org.apache.predictionio.controller.Evaluation
import org.apache.predictionio.controller.MetricEvaluator

object CompleteEvaluation extends Evaluation {
  engineEvaluator = (
    ClassificationEngine(),
    MetricEvaluator(
      metric = Accuracy(),
      otherMetrics = Seq(Precision(0.0), Precision(1.0), Precision(2.0)),
      outputPath = "best.json"))
}
