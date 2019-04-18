#!/bin/bash
#PBS -N exportFluentCFDP
#PBS -l select=1:ncpus=2:mem=20gb
#PBS -l walltime=00:10:00
#PBS -j oe

cd $PBS_O_WORKDIR

casePath=casePathNameThing
initDataPath=initDataPathNameThing
echo "casePath = $casePath"
echo "initDataPath = $initDataPath"

echo "All environment variables:"
printenv

caseFile=$(basename $casePath)
initDataFile=$(basename $initDataPath)


journalFile='CGNSExportJournal.jou'

CFDPostFileName=$(basename $initDataFile .dat)

module purge
module load ansys/19.0
module load intel/19.0

velocities="x-velocity
y-velocity
z-velocity
velocity-magnitude
"
wallShears="
x-wall-shear
y-wall-shear
z-wall-shear
"

pressures="pressure
absolute-pressure
dynamic-pressure
"

miscData="cell-volume
cell-volume-change
cell-wall-distance
curv-corr-fr
turb-kinetic-energy
turb-diss-rate
y-plus
"

cat <<EOT >$journalFile
/file/set-batch-options
; confirm file overwrite?
yes
; Exit on Error?
yes
; Hide Questions?
no
/file/read-case $caseFile
/file/read-data $initDataFile
/file/export/cfd-post-compatible $CFDPostFileName * () * ()
density
viscosity-lam
$velocities
$pressures
$miscData
$wallShears
()
yes
no

exit
yes
EOT

echo "pwd $(pwd)"
echo "ls $(ls)"

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
Case File = $caseFile
Data File = $initDataFile


Output Files:
-----------------
cdat File = ${CFDPostFileName}.cdat

|                                     | 
+-------------------------------------+

"

fluent_args="3ddp -t${tot_cpus} $fluent_args -cnf=$PBS_NODEFILE"

fluent_args="-g -i $journalFile $fluent_args"

##########################################################
#                   Running the Job Itself


for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$casePath $TMPDIR"
	ssh $node "cp $PBS_O_WORKDIR/$initDataPath $TMPDIR"
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
    ssh $node "cp -r $TMPDIR/${CFDPostFileName}.cdat $PBS_O_WORKDIR"
done

