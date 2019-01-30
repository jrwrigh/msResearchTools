#!/bin/bash
#PBS -N ER_m5c1_SST
#PBS -l select=2:ncpus=40:mpiprocs=40:mem=32gb
#PBS -l walltime=02:00:00
#PBS -j oe
#PBS -m abe
#PBS -M jrwrigh@g.clemson.edu

module purge
module add ansys/19.0
module add intel/17.0

echo $SHELL
SHELL="/bin/bash"
set echo on 

echo "###SCRIPT FILE START###"
cat $0
echo "###SCRIPT FILE END###"

cd $PBS_O_WORKDIR

#####################################################################
#                         Parameters

caseFile=ER_m5c1_SST.cas
dataFileName=ER_m5c1_SST
    
num_iterations=1800

SWITCH_ROTATIONAL_VELOCITY=false
rotationalVelocity=0

# Fluent parameters
mpi=intel # MPI options are [ibmmpi, intel, openmpi, cray]
fluentType=3ddp

#####################################################################
#                     Fluent Journal File Logic

if $SWITCH_ROTATIONAL_VELOCITY; then
    rotationalVelocityParameter="/define/parameters/input-parameters/edit \"rotationalVelocity\"

    $rotationalVelocity"
else
    rotationalVelocityParameter=""
fi

#              ^^END Fluent Journal File Logic END^^
#####################################################################

#####################################################################
#                     Name Wrangling

num_nodes=$(cat $PBS_NODEFILE | sort -u | wc -l)
tot_cpus=$(cat $PBS_NODEFILE | wc -l )
jobid_num=$(echo $PBS_JOBID | grep -Eo "[0-9]{3,}")

dataFileName=${jobid_num}_${dataFileName}
outFilePath="$PBS_O_WORKDIR/${dataFileName}.log"
journalFile="$jobid_num"_SST.jou
outDirName=$dataFileName

#####################################################################
#                     Journal File Creation

cat <<EOT >$journalFile
/file/set-batch-options
; confirm file overwrite?
yes
; Exit on Error?
yes
; Hide Questions?
no
/file/read-case $caseFile
$rotationalVelocityParameter
/solve/monitors/residual/convergence-criteria
.00001
.00001
.00001
.00001





!date
report summary no
/server/start-server server_info.txt
/solve/iterate $num_iterations
!date
/file/write-data $dataFileName
exit
yes
EOT
#              ^^END Journal File Creation END^^
#####################################################################

#####################################################################
#                     Building Fluent Arguements

fluent_args="-t${tot_cpus} $fluent_args -cnf=$PBS_NODEFILE"

fluent_args="-g -i $journalFile -mpi=$mpi $fluent_args"

#####################################################################
#                     Printing Job Information

echo "
+--------------------------+
|       START SOLVER       | 
+--------------------------+

+-------------------------------------+
|                                     | 

Start Time : $(date)

Job Information:
----------------
Num. CPUS = $tot_cpus
Num. Nodes = $num_nodes
Job ID # = $jobid_num

Inputs:
----------------
Journal File = $journalFile
Case File = $caseFile
Fluent Verison = $fluentType


Output Files:
-----------------
Data File = ${dataFileName}.dat
Log File = ${dataFileName}.log

Directories:
------------
PBS_O_WORKDIR = $PBS_O_WORKDIR
TMPDIR = $TMPDIR

Other:
-------
Nodes = $(uniq $PBS_NODEFILE)

|                                     | 
+-------------------------------------+

"

#####################################################################
#                     Running the Job Itself

for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$caseFile $TMPDIR"
	ssh $node "mv $PBS_O_WORKDIR/$journalFile $TMPDIR"
done

cd $TMPDIR
printf "Contents of TMPDIR\n"
ls -la
printf "\n\n"

fluent $fluentType $fluent_args > $outFilePath

printf "Simulation Completed\n"

for node in `uniq $PBS_NODEFILE`
do
    ssh $node "mkdir $PBS_O_WORKDIR/$outDirName"
    ssh $node "cp -r $TMPDIR/* $PBS_O_WORKDIR/$outDirName"
done



