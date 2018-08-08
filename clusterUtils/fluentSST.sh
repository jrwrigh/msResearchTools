#!/bin/bash
#PBS -N FluentSST
#PBS -l select=2:ncpus=24:mpiprocs=24:mem=16gb:phase=13
#PBS -l walltime=02:00:00
#PBS -j oe
#PBS -m abe
#PBS -M jrwrigh@g.clemson.edu

module purge
module add ansys/19.0
module add intel/17.0

set echo on 

cd $PBS_O_WORKDIR

FLUENTTYPE=3ddp
CASEFILE=McD13_4S3_SST.cas

DATAFILENAME=McD13_4S3_SST_test
OUTFILE=InitialTest.log

    # MPI options are [ibmmpi, intel, openmpi, cray]
MPI=intel

############
jobid_num=$(echo $PBS_JOBID | grep -Eo "[0-9]{3,}")
OUTFILEPATH="$PBS_O_WORKDIR/${jobid_num}_${OUTFILE}"
DATAFILENAME=${jobid_num}_${DATAFILENAME}.dat

### Making the Journal file
JOURNALFILE=$jobid_num_FluentSST.jou
cat <<EOT >$JOURNALFILE
/file/set-batch-options
; confirm file overwrite?
yes
; Exit on Error?
yes
; Hide Questions?
no
/file/read-case $CASEFILE
!date
/solve/iterate 300
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
	ssh $node "mv $PBS_O_WORKDIR/$JOURNALFILE $TMPDIR"
done

cd $TMPDIR

fluent $FLUENTTYPE $fluent_args > $OUTFILEPATH


for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $TMPDIR/* $PBS_O_WORKDIR"
done



