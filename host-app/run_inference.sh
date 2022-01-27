#!/bin/bash

INPUT_FILE=$1
INPUT_NORMALIZED=${INPUT_FILE/.jpg/.bin}
OUTPUT_FILE=${INPUT_FILE/.jpg/.out}
MODEL=$2
LABELS=$3

if [ "$4" = "int8" ]
then
  MODEL_Q=$MODEL
elif [ "$4" != "float32" ]
then
  echo "Missing arguments"
  exit
fi

./normalize.py $INPUT_FILE $INPUT_NORMALIZED ${MODEL_Q:+-m $MODEL_Q}
touch $OUTPUT_FILE
./build/tf-app $MODEL $INPUT_NORMALIZED $OUTPUT_FILE
./label.py $LABELS $OUTPUT_FILE ${MODEL_Q:+-m $MODEL_Q}
rm $INPUT_NORMALIZED $OUTPUT_FILE
