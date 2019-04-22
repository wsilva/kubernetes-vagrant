#!/bin/bash

QTDENODES=${1:-2}
NODES=1

until [ $NODES -gt $QTDENODES ]
do
  echo "Welcome $NODES times"
  NODES=$((NODES+1))
done
