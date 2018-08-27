#!/bin/bash
#PBS -N FluentSBES
#PBS -l select=4:ncpus=28:mpiprocs=28:mem=32gb:phase=17
#PBS -l walltime=72:00:00
#PBS -j oe
#PBS -m abe
#PBS -M jrwrigh@g.clemson.edu

module purge
module add ansys/19.0
module add intel/17.0

set echo on 

cd $PBS_O_WORKDIR

fluentType=3ddp
caseFile=McD13_4S3_SBES.cas
initDataFile=3980746_McD13_4S3_SST_test.dat

dataFileName=McD13_4S3_SBES_test
outfile=SBESTest.log

    # MPI options are [ibmmpi, intel, openmpi, cray]
MPI=intel

############
jobid_num=$(echo $PBS_JOBID | grep -Eo "[0-9]{3,}")
echo "jobid_num: $jobid_num"
outFilePath="$PBS_O_WORKDIR/${jobid_num}_${outfile}"
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
define/parameters/input-parameters/edit "TimeStepSize"

5e-6
/define/parameters/input-parameters/edit "rotationalVelocity"

0
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

fluent_args="-t${tot_cpus} $fluent_args -cnf=$PBS_NODEFILE"

fluent_args="-g -i $JOURNALFILE -mpi=$MPI $fluent_args"

echo "
+--------------+
| START SOLVER | 
+--------------+

+---------------------------+
|                           | 

Start Time : $(date)


Inputs:
-------------
Journal File = $JOURNALFILE
Case File = $caseFile
Fluent Verison = $fluentType


Output Files:
--------------
Data File = $dataFileName
Log File = $outfile

|                           | 
+---------------------------+

"

for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$caseFile $TMPDIR"
	ssh $node "cp $PBS_O_WORKDIR/$initDataFile $TMPDIR"
	ssh $node "mv $PBS_O_WORKDIR/$JOURNALFILE $TMPDIR"
done

cd $TMPDIR

fluent $fluentType $fluent_args > $outFilePath


for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $TMPDIR/* $PBS_O_WORKDIR"
done



