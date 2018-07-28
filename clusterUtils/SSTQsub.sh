#!/bin/bash
#PBS -N CFXTest
#PBS -l select=1:ncpus=2:mpiprocs=2:mem=15gb:phase=8c
#PBS -l walltime=02:00:00
#PBS -j oe

module purge
module add ansys/19.0
module add intel/17.0

DEFFILE=Test.def

cd $PBS_O_WORKDIR

machines=$(uniq -c $PBS_NODEFILE | awk '{print $2"*"$1}' | tr '\n' ,)

echo "$machines \n"

SCRATCH=/local_scratch/$USER

for node in `uniq $PBS_NODEFILE`
do
	ssh $node "mkdir -p $SCRATCH"
	ssh $node "cp $PBS_O_WORKDIR/$DEFFILE $SCRATCH"
done

cd $SCRATCH

cfx5solve -batch -def $DEFFILE -double -par-dist "$machines" -job -output-summary-option 3 -verbose


for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $SCRATCH/* $PBS_O_WORKDIR"
    ssh $node "rm -rf $SCRATCH"
done
