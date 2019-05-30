#!/bin/zsh
qsub -I -X -l select=1:ncpus=4:mem=32gb,walltime=72:00:00

# module load ansys/19.0
