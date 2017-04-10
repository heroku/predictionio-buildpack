package org.template.classification

import org.apache.predictionio.controller.EngineFactory
import org.apache.predictionio.controller.Engine

class Query(
  val voice_usage : Double,
  val data_usage : Double,
  val text_usage : Double
) extends Serializable

class PredictedResult(
  val service_plan: Double
) extends Serializable

class ActualResult(
  val service_plan: Double
) extends Serializable

object ClassificationEngine extends EngineFactory {
  def apply() = {
    new Engine(
      classOf[DataSource],
      classOf[Preparator],
      Map(
        "randomforest"  -> classOf[RandomForestAlgorithm]),
      classOf[Serving])
  }
}
