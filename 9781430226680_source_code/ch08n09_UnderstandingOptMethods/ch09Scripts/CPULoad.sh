#!/bin/bash
i=0
STime=`date +%s`

while [ `date +%s` -lt $(($STime+$((600)))) ]; do
  i=i+0.000001
done
