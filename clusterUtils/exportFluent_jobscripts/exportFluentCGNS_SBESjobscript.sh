#!/bin/bash
#PBS -N exportFluentCGNS
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

    # cellCentered=no for Node value points, yes for Cell Centered points
cellCentered='no'

journalFile='CGNSExportJournal.jou'

cgnsFileName=$(basename $initDataFile .dat)

module purge
module load ansys/19.0
module load intel/19.0

velocities="x-velocity
y-velocity
z-velocity
rmse-x-velocity
rmse-y-velocity
rmse-z-velocity
mean-x-velocity
mean-y-velocity
mean-z-velocity
"
wallShears="
mean-x-wall-shear
mean-y-wall-shear
mean-z-wall-shear
"

pressures="mean-dynpres_unsteady
rmse-dynpres_unsteady
dynpres_unsteady
pressure
absolute-pressure
"

miscData="mean-sbes-shield-value
rmse-sbes-shield-value
sbes-shield-value
cell-volume
cell-volume-change
cell-wall-distance
cell-convective-courant-number
curv-corr-fr
turb-kinetic-energy
turb-diss-rate
y-plus
"
reynoldsStresses="resolved-uv-stress
resolved-uw-stress
resolved-vw-stress
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
/file/export/cgns $cgnsFileName $cellCentered 
density
viscosity-lam
$velocities
$pressures
$miscData
$reynoldsStresses
$wallShears
()

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
CGNS File = ${cgnsFileName}.cgns

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
    ssh $node "cp -r $TMPDIR/${cgnsFileName}.cgns $PBS_O_WORKDIR"
done

