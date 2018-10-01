#!/bin/bash
#PBS -N PlenumMeshTestSST5_S0
#PBS -l select=2:ncpus=20:mpiprocs=20:mem=32gb:phase=11a
#PBS -l walltime=02:00:00
#PBS -j oe
#PBS -m abe
#PBS -M jrwrigh@g.clemson.edu

module purge
module add ansys/19.0
module add intel/17.0

set echo on 

echo "###SCRIPT FILE START###"
cat $0
echo "###SCRIPT FILE END###"

cd $PBS_O_WORKDIR

FLUENTTYPE=3ddp
CASEFILE=PlenumMeshTestSST4.cas

DATAFILENAME=PlenumMeshTest_SST
OUTFILE=PlenumMeshTest_SST.log

    # MPI options are [ibmmpi, intel, openmpi, cray]
MPI=intel

############
jobid_num=$(echo $PBS_JOBID | grep -Eo "[0-9]{3,}")
OUTFILEPATH="$PBS_O_WORKDIR/${jobid_num}_${OUTFILE}"
DATAFILENAME=${jobid_num}_${DATAFILENAME}.dat

### Making the Journal file
JOURNALFILE="$jobid_num"_FluentSST.jou
cat <<EOT >$JOURNALFILE
/file/set-batch-options
; confirm file overwrite?
yes
; Exit on Error?
yes
; Hide Questions?
no
/file/read-case $CASEFILE
/define/parameters/input-parameters/edit "rotationalVelocity"

0
/solve/monitors/residual/convergence-criteria
.00001
.00001
.00001
.00001





!date
/solve/iterate 1800
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



