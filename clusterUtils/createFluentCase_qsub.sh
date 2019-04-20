#!/bin/bash

# Run the job script files
# Arguements: [SBES|SST] [meshName] [Swirl#] 

jobScriptPath="/home/jrwrigh/gitRepos/msresearchtools/clusterUtils/createFluentCase_jobscript.sh"
profilesDirPath="/common/miller/jrwrigh/DesignSpaceSims/profiles"
settingsDirPath="/common/miller/jrwrigh/DesignSpaceSims/settings"

jobScriptName=$(basename $jobScriptPath)

    # copy the PBS job script to the current directory
cp $jobScriptPath .

## GET PROFILE NAME BASED ON SWIRL#
turbProfileFilePath=$(ls $profilesDirPath/*Turb**$3*)
velocityProfileFilePath=$(ls $profilesDirPath/*Vel**$3*)

## GET settings NAME BASED ON SBES/SST
settingsFilePath=$(ls $settingsDirPath/$1.settings)
settingsProfileFilePath=$(ls $settingsDirPath/$1.settings.prof)

## Create case file name
geometryName=$(basename $2 .msh)
caseFileName=${geometryName}_$3_$1

    # copy the file paths into the jobScript
sed -i "s@meshPathNameThing@$2@" $jobScriptName
sed -i "s@settingsPathNameThing@$settingsFilePath@" $jobScriptName
sed -i "s@settingsProfilePathNameThing@$settingsProfileFilePath@" $jobScriptName
sed -i "s@turbProfilePathNameThing@$turbProfileFilePath@" $jobScriptName
sed -i "s@velocityProfilePathNameThing@$velocityProfileFilePath@" $jobScriptName
sed -i "s@caseFileNameThing@$caseFileName@" $jobScriptName

qsub $jobScriptName

rm $jobScriptName
