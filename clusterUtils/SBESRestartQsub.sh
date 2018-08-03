#!/bin/bash
#PBS -N 20180727_AR1.30_phi4_octov2SBES
#PBS -l select=4:ncpus=28:mpiprocs=28:mem=32gb:phase=16
#PBS -l walltime=72:00:00
#PBS -j oe

module purge
module add ansys/19.0
module add intel/17.0

DEFFILE=20180801_McD13_4S3_SBES.def
RESTARTFILE=20180801_McD13_4S3_SBES_001.res

cd $PBS_O_WORKDIR

machines=$(uniq -c $PBS_NODEFILE | awk '{print $2"*"$1}' | tr '\n' ,)

echo "$machines \n"

for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$DEFFILE $TMPDIR"
	ssh $node "cp $PBS_O_WORKDIR/$RESTARTFILE $TMPDIR"
done

cd $TMPDIR

cfx5solve -batch -continue-from-file $RESTARTFILE -def $DEFFILE -double -par-dist "$machines" -job -output-summary-option 3 -verbose -size 1.1

for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $TMPDIR/* $PBS_O_WORKDIR"
done
