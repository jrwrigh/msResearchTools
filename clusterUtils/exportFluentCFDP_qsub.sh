#!/bin/bash
# NOTE: This script requires the associated PBS Job Script to work along side it.
# Arguements: [SBES|SST] [caseName] [initDataPath]

if [ "$1" == "-h" ]; then
    echo "exportFluentCFDP [SBES|SST] [caseName] [initDataPath]"
    exit 1
fi

jobScriptPathSBES="/home/jrwrigh/gitRepos/msresearchtools/clusterUtils/exportFluent_jobscripts/exportFluentCFDP_SBESjobscript.sh"
jobScriptPathSST="/home/jrwrigh/gitRepos/msresearchtools/clusterUtils/exportFluent_jobscripts/exportFluentCFDP_SSTjobscript.sh"
if [ $1 = "SBES" ]; then
    jobScriptName=$(basename $jobScriptPathSBES)
        # copy the PBS job script to the current directory
    cp $jobScriptPathSBES .
else
    jobScriptName=$(basename $jobScriptPathSST)
        # copy the PBS job script to the current directory
    cp $jobScriptPathSST .
fi

    # copy the casePath and initDataPath names into the jobScript
sed -i "s/casePathNameThing/$2/" $jobScriptName
sed -i "s/initDataPathNameThing/$3/" $jobScriptName

qsub $jobScriptName

rm $jobScriptName
