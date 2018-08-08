#!/bin/bash
#PBS -N FluentSBES
#PBS -l select=3:ncpus=40:mpiprocs=40:mem=32gb:phase=18b
#PBS -l walltime=04:00:00
#PBS -j oe
#PBS -m abe
#PBS -M jrwrigh@g.clemson.edu

module purge
module add ansys/19.0
module add intel/17.0

set echo on 

cd $PBS_O_WORKDIR

FLUENTTYPE=3ddp
CASEFILE=McD13_4S3_SBES.cas
INITDATAFILE=3927650_McD13_4S3_SST_test.dat

DATAFILENAME=McD13_4S3_SBES_test
OUTFILE=SBESTest.log

    # MPI options are [ibmmpi, intel, openmpi, cray]
MPI=intel

############
jobid_num=$(echo $PBS_JOBID | grep -Eo "[0-9]{3,}")
echo "jobid_num: $jobid_num"
OUTFILEPATH="$PBS_O_WORKDIR/${jobid_num}_${OUTFILE}"
DATAFILENAME=${jobid_num}_${DATAFILENAME}.dat

### Making the Journal file
JOURNALFILE="$jobid_num"_FluentSBES.jou
cat <<EOT >$JOURNALFILE
/file/set-batch-options
; confirm file overwrite?
yes
; Exit on Error?
yes
; Hide Questions?
no
/file/read-case $CASEFILE
/file/read-data $INITDATAFILE
/solve/initialize/init-instantaneous-vel
define/parameters/input-parameters/edit "TimeStepSize"

5e-6
!date
/solve/dual-time-iterate 20



!date
/file/write-data $DATAFILENAME
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
Case File = $CASEFILE
Fluent Verison = $FLUENTTYPE


Output Files:
--------------
Data File = $DATAFILENAME
Log File = $OUTFILE

|                           | 
+---------------------------+

"

for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$CASEFILE $TMPDIR"
	ssh $node "cp $PBS_O_WORKDIR/$INITDATAFILE $TMPDIR"
	ssh $node "mv $PBS_O_WORKDIR/$JOURNALFILE $TMPDIR"
done

cd $TMPDIR

fluent $FLUENTTYPE $fluent_args > $OUTFILEPATH


for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $TMPDIR/* $PBS_O_WORKDIR"
done



