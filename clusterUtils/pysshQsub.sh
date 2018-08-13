#!/bin/bash
#PBS -N testjobsleep
#PBS -l select=1:ncpus=2:mpiprocs=2:mem=4gb:phase=5a
#PBS -l walltime=02:00:00


cd $TMPDIR
touch testfile
sleep 2h

