#!/bin/bash
#PBS -N CFXTest
#PBS -l select=1:ncpus=2:mpiprocs=2:mem=15gb
#PBS -l walltime=02:00:00
#PBS -j oe

module purge
module add ansys/19.0
module add intel/17.0

cd $PBS_O_WORKDIR

machines=$(uniq -c $PBS_NODEFILE | awk '{print $2"*"$1}' | tr '\n' ,)

echo "machines=$machines \n"

cfx5solve -batch -def /scratch2/jrwrigh/Test.def -double -par-dist "$machines" -job -output-summary-option 3 -verbose
