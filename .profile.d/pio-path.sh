#!/usr/bin/env bash

# PATH must include
# * the bin/ where `pio build` ran (for an engine)
# * just the distribution's bin/ (for the eventserver)
# * also access to the `sbt` executable that is include in the distribution
WORKING_DIR=`pwd`
export PATH="$WORKING_DIR/pio-engine/PredictionIO-dist/bin:$WORKING_DIR/pio-engine/PredictionIO-dist/sbt:$WORKING_DIR/PredictionIO-dist/bin:$WORKING_DIR/PredictionIO-dist/sbt:$PATH"
