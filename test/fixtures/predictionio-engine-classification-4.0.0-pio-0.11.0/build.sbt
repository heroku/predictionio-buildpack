name := "template-scala-parallel-classification"

organization := "org.apache.predictionio"

scalaVersion := "2.11.8"

libraryDependencies ++= Seq(
  "org.apache.predictionio" %% "apache-predictionio-core" % "0.11.0-incubating" % "provided",
  "org.apache.spark"        %% "spark-core"               % "2.1.0" % "provided",
  "org.apache.spark"        %% "spark-mllib"              % "2.1.0" % "provided",
  "org.scalatest"           %% "scalatest"                % "2.2.1" % "test")

parallelExecution in Test := false
