#!/bin/bash
#PBS -N FluentSST
#PBS -l select=1:ncpus=2:mpiprocs=2:mem=15gb:phase=16
#PBS -l walltime=02:00:00
#PBS -j oe

module purge
module add ansys/19.0
module add intel/17.0

cd $PBS_O_WORKDIR

FLUENTTYPE=3ddp
JOURNALFILE=dfsdasddsdasf.jou
CASEFILE=asdfasddsadasf.cas

DATAFILENAME=asdfasddasfsadf.dat
OUTFILE=asdfsdafadsf.log

############
num_nodes=$(cat $PBS_NODEFILE | sort -u | wc -l)
tot_cpus=$(cat $PBS_NODEFILE | wc -l )
cpus_per_node=$(expr $tot_cpus /* $num_nodes)

fluent_args="-t ${cpus_per_node} $fluent_args -cnf=$PBS_NODEFILE"

fluent_args="-g -i $JOURNALFILE $fluent_args"

echo "#################################################
#          START SOLVER 

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
################################################
"

for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$CASEFILE $TMPDIR"
	ssh $node "cp $PBS_O_WORKDIR/$JOURNALFILE $TMPDIR"
done

cd $TMPDIR

fluent $fluent_args > $OUTFILE


for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $TMPDIR/* $PBS_O_WORKDIR"
done



