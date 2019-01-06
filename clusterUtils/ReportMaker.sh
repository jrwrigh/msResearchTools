#!/bin/bash
#PBS -N ReportMaker
#PBS -l select=1:ncpus=2:mpiprocs=2:mem=15gb:phase=8c
#PBS -l walltime=00:30:00
#PBS -j oe

module purge
module add ansys/19.0

RESFILE=20180727_something_something.res
CSEFILE=CFDPostReportTest.cse

cd $PBS_O_WORKDIR

machines=$(uniq -c $PBS_NODEFILE | awk '{print $2"*"$1}' | tr '\n' ,)

echo "$machines \n"


for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$ciw;ljkasdf;lakj sd;lkj asfd;l $TMPDIR"
done

cd $SCRATCH

cfdpost -batch $CSEFILE $RESFILE


for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $TMPDIR/* $PBS_O_WORKDIR"
done
