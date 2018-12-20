#!/bin/bash
#PBS -N ERCOFTAC_m2c1_SBES_specsynth
#PBS -l select=1:ncpus=40:mpiprocs=40:mem=30gb
#PBS -l walltime=72:00:00
#PBS -j oe
#PBS -m abe
#PBS -M jrwrigh@g.clemson.edu

module purge
module add ansys/19.0
module add intel/17.0

set echo on 
echo "###START NOTES###" 
echo "Spectral Synthesizer used for Velocity perturbation"
echo "###END NOTES###"

echo "#######################"
echo "###SCRIPT FILE START###"
echo "#######################"
echo ""
cat $0
echo ""
echo "#####################"
echo "###SCRIPT FILE END###"
echo "#####################"

cd $PBS_O_WORKDIR

num_iterations=20000
timeStep=1e-5
init_num_iterations=500
initTimeStep=5e-8
autosave_frequency=2000
autosave_maxfilestokeep=1

fluentType=3d
caseFile=ERCOFTAC_m2c1_SBES_specsynth.cas
initDataFile=4783505_ERCOFTAC_m2c1_SST.dat
dataFileName=ERCOFTAC_m2c1_SBES

    # MPI options are [ibmmpi, intel, openmpi, cray]
MPI=intel

############
jobid_num=$(echo $PBS_JOBID | grep -Eo "[0-9]{3,}")
echo "jobid_num: $jobid_num"
dataFileName=${jobid_num}_${dataFileName}
outFilePath="$PBS_O_WORKDIR/${dataFileName}.log"

### Making the Journal file
journalFile="$jobid_num"_FluentSBES.jou
cat <<EOT >$journalFile
/file/set-batch-options
; confirm file overwrite?
yes
; Exit on Error?
yes
; Hide Questions?
no
/file/read-case $caseFile
/file/read-data $initDataFile
/solve/initialize/init-instantaneous-vel
; /solve/initialize/init-flow-statistics
; 24= Coupled
; /solve/set/p-v-coupling 24

; RELAXATION FACTORS
; Default: 1[body-force,density] 0.7[mom] 0.8[turbvisc,omega,k] 0.3[pressure]
; /solve/set/under-relaxation/body-force 1
; /solve/set/under-relaxation/mom 0.7
; /solve/set/under-relaxation/turb-viscosity 0.8
; /solve/set/under-relaxation/density 1
; /solve/set/under-relaxation/omega 0.8
; /solve/set/under-relaxation/k 0.8
; /solve/set/under-relaxation/pressure 0.3
define/parameters/input-parameters/edit "TimeStepSize"

$initTimeStep
/solve/monitors/residual/convergence-criteria
.001
.0001
.0001
.0001




; AUTOSAVE SETTINGS
/file/auto-save/retain-most-recent-files yes
/file/auto-save/max-files $autosave_maxfilestokeep
/file/auto-save/data-frequency $autosave_frequency
/file/auto-save/append-file-name-with time-step 6
/file/auto-save/root-name "${PBS_O_WORKDIR}/$dataFileName"

/server/start-server server_info.txt
!date
/solve/dual-time-iterate $init_num_iterations

; collect stats?, sampleInt, flow shear?, flow heat?, wall stats?
; solve/set/data-sampling yes $sampleInterval yes no yes
define/parameters/input-parameters/edit "TimeStepSize"

$timeStep
/solve/dual-time-iterate $num_iterations

!date
/parallel/timer/usage
/file/write-data ${dataFileName}.dat
exit
yes
EOT

num_nodes=$(cat $PBS_NODEFILE | sort -u | wc -l)
echo "\$num_nodes = " $num_nodes
tot_cpus=$(cat $PBS_NODEFILE | wc -l )
echo "\$tot_cpus = " $tot_cpus

fluent_args="-t${tot_cpus} $fluent_args -cnf=$PBS_NODEFILE"

fluent_args="-g -i $journalFile -mpi=$MPI $fluent_args"

echo "
+--------------+
| START SOLVER | 
+--------------+

+---------------------------+
|                           | 

Start Time : $(date)


Inputs:
-------------
Journal File = $journalFile
Case File = $caseFile
Fluent Verison = $fluentType


Output Files:
--------------
Data File = ${dataFileName}.dat
Log File = ${dataFileName}.log

|                           | 
+---------------------------+

"

for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$caseFile $TMPDIR"
	ssh $node "cp $PBS_O_WORKDIR/$initDataFile $TMPDIR"
	ssh $node "mv $PBS_O_WORKDIR/$journalFile $TMPDIR"
done

cd $TMPDIR

fluent $fluentType $fluent_args > $outFilePath

for filename in *.out
do 
    mv $filename ${filename%.out}_${jobid_num}.out
done

for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $TMPDIR/* $PBS_O_WORKDIR"
done



