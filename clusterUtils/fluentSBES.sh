#!/bin/bash
#PBS -N PlenumMeshTest3SBES1
#PBS -l select=3:ncpus=40:mpiprocs=40:mem=30gb:phase=18b
#PBS -l walltime=72:00:00
#PBS -j oe
#PBS -m abe
#PBS -M jrwrigh@g.clemson.edu

module purge
module add ansys/19.0
module add intel/17.0

set echo on 

echo "###START NOTES###"
echo "S3, Dewoestine inlet profile, vortex method (190 points), timestep 5e-8"
echo "###END NOTES###"

echo "#######################"
echo "###SCRIPT FILE START###"
echo "#######################"
echo ""
cat $0
echo ""
echo "#####################"
echo "###SCRIPT FILE END###"
echo "#####################"

cd $PBS_O_WORKDIR

num_iterations=5000
timeStep=5e-8
autosave_frequency=5000
autosave_maxfilestokeep=3

fluentType=3ddp
caseFile=PlenumMeshTest3_SBES3.cas
initDataFile=4278672_PlenumMeshTest3_SST1_S3.dat
dataFileName=PlenumMeshTest3_SBES3_S3

    # MPI options are [ibmmpi, intel, openmpi, cray]
MPI=intel

############
jobid_num=$(echo $PBS_JOBID | grep -Eo "[0-9]{3,}")
echo "jobid_num: $jobid_num"
dataFileName=${jobid_num}_${dataFileName}
outFilePath="$PBS_O_WORKDIR/${dataFileName}.log"

### Making the Journal file
journalFile="$jobid_num"_FluentSBES.jou
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
/solve/initialize/init-instantaneous-vel
; 24= Coupled
; /solve/set/p-v-coupling 24
define/parameters/input-parameters/edit "TimeStepSize"

$timeStep
/solve/monitors/residual/convergence-criteria
.0001
.0001
.0001
.0001




; Autosave Settings
/file/auto-save/retain-most-recent-files yes
/file/auto-save/max-files $autosave_maxfilestokeep
/file/auto-save/data-frequency $autosave_frequency
/file/auto-save/append-file-name-with time-step 6
/file/auto-save/root-name "${PBS_O_WORKDIR}/$dataFileName"

/server/start-server server_info.txt
!date
/solve/dual-time-iterate $num_iterations

!date
/parallel/timer/usage
/file/write-data ${dataFileName}.dat
exit
yes
EOT

num_nodes=$(cat $PBS_NODEFILE | sort -u | wc -l)
echo "\$num_nodes = " $num_nodes
tot_cpus=$(cat $PBS_NODEFILE | wc -l )
echo "\$tot_cpus = " $tot_cpus

fluent_args="-t${tot_cpus} $fluent_args -cnf=$PBS_NODEFILE"

fluent_args="-g -i $journalFile -mpi=$MPI $fluent_args"

echo "
+--------------+
| START SOLVER | 
+--------------+

+---------------------------+
|                           | 

Start Time : $(date)


Inputs:
-------------
Journal File = $journalFile
Case File = $caseFile
Fluent Verison = $fluentType


Output Files:
--------------
Data File = ${dataFileName}.dat
Log File = ${dataFileName}.log

|                           | 
+---------------------------+

"

for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$caseFile $TMPDIR"
	ssh $node "cp $PBS_O_WORKDIR/$initDataFile $TMPDIR"
	ssh $node "mv $PBS_O_WORKDIR/$journalFile $TMPDIR"
done

cd $TMPDIR

fluent $fluentType $fluent_args > $outFilePath

for filename in *.out
do 
    mv $filename ${filename%.out}_${jobid_num}.out
done

for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $TMPDIR/* $PBS_O_WORKDIR"
done



