#!/bin/bash

# Script to assist the launching of a Paraview server on the Palmetto Cluster
# Usage:
# 	1) Run script to start the interactive session on the cluster
#	2) Run the script again (in the interactive session) to start the Paraview server
### NOTE: simg file must be in the working directory when running the second time (ie. in the interactive job)

simgPath="paraview_5.6.0RC3-egl.simg"
nodehost=${HOSTNAME:0:4} 
nodenumber=${HOSTNAME:5:9}

if [ "$nodehost" == "node" ]; then
    module unload python
	module load singularity
	export DISPLAY=:0
	export SINGULARITY="$(which singularity) exec -B /common/miller/jrwrigh:/common -B /usr/lib64/nvidia/:/.singularity.d/libs -B /etc/machine-id:/etc/machine-id -B /run/user:/run/user -B /usr/bin:/host_bin -B $(pwd):/host_pwd ${simgPath}" 

    echo "
    Command for PuTTY SSH port forwarding:
    putty -ssh -L 10000:$HOSTNAME:11111 jrwrigh@login.palmetto.clemson.edu
    "

	${SINGULARITY} pvserver -display :0
 
else 
	qsub -I -l select=1:ncpus=2:ngpus=1:mem=20gb,walltime=4:00:00
fi 

