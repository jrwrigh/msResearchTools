#!/bin/bash
# NOTE: This script requires the associated PBS Job Script to work along side it.
# Arguements: [caseName] [initDataPath]

jobScriptPath="/home/jrwrigh/gitRepos/msresearchtools/clusterUtils/exportFluentCGNS_jobscript.sh"
jobScriptName=$(basename $jobScriptPath)

    # copy the PBS job script to the current directory
cp $jobScriptPath .

    # copy the casePath and initDataPath names into the jobScript
sed -i "s/casePathNameThing/$1/" $jobScriptName
sed -i "s/initDataPathNameThing/$2/" $jobScriptName

qsub $jobScriptName

rm $jobScriptName
