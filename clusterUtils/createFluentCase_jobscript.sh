#!/bin/bash
#PBS -N createFluentCase
#PBS -l select=1:ncpus=2:mem=20gb
#PBS -l walltime=00:10:00
#PBS -j oe

cd $PBS_O_WORKDIR

meshPath=meshPathNameThing
settingsPath=settingsPathNameThing
settingsProfilePath=settingsProfilePathNameThing
velocityProfilePath=velocityProfilePathNameThing
turbProfilePath=turbProfilePathNameThing

echo "meshPath = $meshPath"
echo "settingsPath = $settingsPath"
echo "velocityProfilePath = $velocityProfilePath"
echo "turbProfilePath = $turbProfilePath"
echo "

"
echo "All environment variables:"
printenv

meshFile=$(basename $meshPath)
settingsFile=$(basename $settingsPath)
velocityProfileFile=$(basename $velocityProfilePath)
turbProfileFile=$(basename $turbProfilePath)

caseFileName=caseFileNameThing

journalFile='createFluentCase.jou'

module purge
module load ansys/19.0
module load intel/19.0

cat <<EOT >$journalFile
/file/set-batch-options
; confirm file overwrite?
yes
; Exit on Error?
yes
; Hide Questions?
no
/file/read-case $meshFile
/mesh/scale .001 .001 .001
/file/read-settings $settingsFile
/file/read-profile $velocityProfileFile
/file/read-profile $turbProfileFile
/file/write-case $caseFileName

exit
yes
EOT

echo "
############################################
#          PRINT JOURNAL FILE              #
############################################
"
cat $journalFile
echo "
############################################
#           END JOURNAL FILE               #
############################################
"

echo "
+--------------------------+
|       START SOLVER       | 
+--------------------------+

+-------------------------------------+
|                                     | 

Start Time : $(date)

Inputs:
----------------
Journal File = $journalFile
Mesh File = $meshFile
Settings File = $settingsFile
Velocity Profile File = $velocityProfileFile
Turbulence Profile File = $turbProfileFile



Output Files:
-----------------
Case File = ${caseFileName}.cas

|                                     | 
+-------------------------------------+

"

fluent_args="3ddp -t${tot_cpus} $fluent_args -cnf=$PBS_NODEFILE"

fluent_args="-g -i $journalFile $fluent_args"

##########################################################
#                   Running the Job Itself


for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$meshPath $TMPDIR"
	ssh $node "cp $settingsPath $TMPDIR"
	ssh $node "cp $settingsProfilePath$TMPDIR"
	ssh $node "cp $velocityProfilePath $TMPDIR"
	ssh $node "cp $turbProfilePath $TMPDIR"
	ssh $node "mv $PBS_O_WORKDIR/$journalFile $TMPDIR"
done

cd $TMPDIR
echo "
List Contents of $TMPDIR:

"
ls -al

fluent $fluentType $fluent_args

echo "
List Contents of $TMPDIR After Fluent run:
"
ls -al

for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $TMPDIR/${caseFileName}.cas $PBS_O_WORKDIR"
done

