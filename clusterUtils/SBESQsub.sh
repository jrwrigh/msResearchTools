#!/bin/bash
#PBS -N 20180727_AR1.30_phi4_octov2SBES
#PBS -l select=2:ncpus=28:mpiprocs=28:mem=32gb:phase=16
#PBS -l walltime=72:00:00
#PBS -j oe
#PBS -m abe
#PBS -M jrwrigh@g.clemson.edu

module purge
module add ansys/19.0
module add intel/17.0

DEFFILE=20180727_AR1.30_phi4_octov2SBES.def
INITFILE=20180727_AR1.30_phi4_octov2_001.res
# SCRATCHDIRECTORY=/scratch1/jrwrigh/20180727_AR1.30_phi4_octov2SBES

cd $PBS_O_WORKDIR

machines=$(uniq -c $PBS_NODEFILE | awk '{print $2"*"$1}' | tr '\n' ,)

echo "$machines \n"

for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$INITFILE $TMPDIR"
	ssh $node "cp $PBS_O_WORKDIR/$DEFFILE $TMPDIR"
done

cd $TMPDIR

cfx5solve -batch -def $DEFFILE -initial-file $INITFILE -double -par-dist "$machines" -job -output-summary-option 3 -verbose 

for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $TMPDIR/* $PBS_O_WORKDIR"
done
