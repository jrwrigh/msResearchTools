#!/bin/bash
#PBS -N PlenumMeshTestSBES6
#PBS -l select=3:ncpus=40:mpiprocs=40:mem=32gb:phase=18b
#PBS -l walltime=72:00:00
#PBS -j oe
#PBS -m abe
#PBS -M jrwrigh@g.clemson.edu

module purge
module add ansys/19.0
module add intel/17.0

set echo on 

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

fluentType=3ddp
caseFile=PlenumMeshTestSBES6.cas
initDataFile=4012839_PlenumMeshTest_SST.dat

dataFileName=PlenumMeshTest_SBES6_S3
outFile=SBES6_S3.log

    # MPI options are [ibmmpi, intel, openmpi, cray]
MPI=intel

############
jobid_num=$(echo $PBS_JOBID | grep -Eo "[0-9]{3,}")
echo "jobid_num: $jobid_num"
outFilePath="$PBS_O_WORKDIR/${jobid_num}_${outFile}"
dataFileName=${jobid_num}_${dataFileName}.dat

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

5e-6
/define/parameters/input-parameters/edit "rotationalVelocity"

916.7
/solve/monitors/residual/convergence-criteria
.0001
.0001
.0001
.0001




/server/start-server server_info.txt
!date
/solve/dual-time-iterate 40000

!date
/parallel/timer/usage
/file/write-data $dataFileName
exit
yes
EOT

num_nodes=$(cat $PBS_NODEFILE | sort -u | wc -l)
echo "\$num_nodes = " $num_nodes
tot_cpus=$(cat $PBS_NODEFILE | wc -l )
echo "\$tot_cpus = " $tot_cpus

fluent_args="-t${tot_cpus} -cflush $fluent_args -cnf=$PBS_NODEFILE"

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
Data File = $dataFileName
Log File = $outFile

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


for node in `uniq $PBS_NODEFILE`
do
    ssh $node "mv *.out report-0_$(jobid_num).out"
    ssh $node "cp -r $TMPDIR/* $PBS_O_WORKDIR"
done



