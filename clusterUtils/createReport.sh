#!/bin/bash

# Arguements: [SST|SBES] [data file]

if [ "$1" == "-h" ]; then
    echo "createReport [SST|SBES] [data file]"
    exit 1
fi

dataFile=$2
reportStateDirPath='/common/miller/jrwrigh/DesignSpaceSims/cfdpost_statefiles'

jobScriptName=createReport_jobscript.sh
if [ $1 = "SST" ]; then
    reportStateFilePath=$(ls $reportStateDirPath/*SST*.cst)
else
    reportStateFilePath=$(ls $reportStateDirPath/*SBES*.cst)
fi

reportFileName=$(basename $dataFile .cdat)_Report

echo cfdpost -report $reportStateFilePath -name $reportFileName -outdir ./ ./$dataFile

cfdpost -report $reportStateFilePath -name $reportFileName -outdir ./ ./$dataFile

