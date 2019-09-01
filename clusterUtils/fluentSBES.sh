#!/bin/bash
#PBS -N p131L32S75_SBES
#PBS -l select=1:ncpus=28:ngpus=0:mpiprocs=28:mem=30gb
#PBS -l walltime=72:00:00
#PBS -j oe
#PBS -m abe
#PBS -M jrwrigh@g.clemson.edu

module purge
module add ansys/19.0
module add intel/19.0

set echo on 
set -o xtrace
echo "###START NOTES###" 
echo ""
echo "###END NOTES###"

echo ""
echo "#########################################################################"
echo "###                       SCRIPT FILE START                           ###"
echo "#########################################################################"
echo ""
cat $0
echo ""
echo "#########################################################################"
echo "###                        SCRIPT FILE END                            ###"
echo "#########################################################################"
echo ""

cd $PBS_O_WORKDIR

#####################################################################
#                         Parameters

SWITCH_INITIALIZE_UNSTEADY_STATISTICS=false

num_iterations=10000
timeStep=7e-5

SWITCH_INITIAL_ITERATIONS=false
init_num_iterations=100
initTimeStep=5e-6

SWITCH_UNSTEADY_STAT_INITIALIZATION=false
    # drops the first N timesteps from the data
unsteadyStatIterations=4000
unsteadyStatTimeStep=$timeStep

autosave_frequency=500
autosave_maxfilestokeep=1

    # MPI options are [ibmmpi, intel, openmpi, cray]
MPI=intel
fluentType=3d
export I_MPI_FABRICS=shm:tcp

casePath=p131L0325_S075_SBES.cas
initDataPath=6077765_p131L0325_S075_SBES/6077765_p131L0325_S075_SBES.dat
dataFileName=p131L0325_S075_SBES
outDirPath="/scratch2/jrwrigh"

SWITCH_DROP_CACHE=false

# Relaxation Parameter settings
SWITCH_CHANGE_RELAX_PARAMS=true
    # Default: 1[body-force,density] 0.7[mom] 0.8[turbvisc,omega,k] 0.3[pressure]
bodyforce_relax=1
density_relax=1
mom_relax=0.7
turbvisc_relax=0.8
omega_relax=0.8
k_relax=0.8
pressure_relax=0.8

#####################################################################
#                     Name Wrangling

num_nodes=$(cat $PBS_NODEFILE | sort -u | wc -l)
tot_cpus=$(cat $PBS_NODEFILE | wc -l )
jobid_num=$(echo $PBS_JOBID | grep -Eo "[0-9]{3,}")

caseFile="$(basename $casePath)"
initDataFile="$(basename $initDataPath)"
dataFileName=${jobid_num}_${dataFileName}
outFilePath="${outDirPath}/${dataFileName}.log"
journalFile="$jobid_num"_FluentSBES.jou
outDirName=$dataFileName

#####################################################################
#                     Fluent Journal File Logic

if $SWITCH_INITIAL_ITERATIONS; then
    init_iterations="define/parameters/input-parameters/edit \"TimeStepSize\"

    $initTimeStep
    /solve/dual-time-iterate $init_num_iterations"
else
    init_iterations=
fi

if $SWITCH_CHANGE_RELAX_PARAMS; then
    relax_SIMPLE="/solve/set/under-relaxation/body-force $bodyforce_relax
    /solve/set/under-relaxation/mom $mom_relax
    /solve/set/under-relaxation/turb-viscosity $turbvisc_relax
    /solve/set/under-relaxation/density $density_relax
    /solve/set/under-relaxation/omega $omega_relax
    /solve/set/under-relaxation/k $k_relax
    /solve/set/under-relaxation/pressure $pressure_relax"
else
    relax_SIMPLE=
fi

if $SWITCH_INITIALIZE_UNSTEADY_STATISTICS; then
    initFlowStatistics="/solve/initialize/init-flow-statistics"
else
    initFlowStatistics=
fi

if $SWITCH_DROP_CACHE; then
    dropCache="(flush-cache)"
else
    dropCache=
fi

if $SWITCH_UNSTEADY_STAT_INITIALIZATION; then
    unsteadyStatInitialization="define/parameters/input-parameters/edit \"TimeStepSize\"

    $unsteadyStatTimeStep
    /solve/dual-time-iterate $unsteadyStatIterations

    /solve/initialize/init-flow-statistics    
    "
else
    unsteadyStatInitialization=
fi

DATATYPEEXT="${initDataFile##*.}"
if [ "$DATATYPEEXT" = "ip" ]; then
    initializeDomain="file/interpolate/read-data $initDataFile"
elif [ "$DATATYPEEXT" = "dat" ]; then
    initializeDomain="/file/read-data $initDataFile"
else
    echo "INITDATATYPE \"$INITDATATYPE\" not a valid term"
    exit 1
fi

#              ^^END Fluent Journal File Logic END^^
#####################################################################

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
/server/start-server server_info.txt
$dropCache
/file/read-case $caseFile
$initializeDomain
/solve/initialize/init-instantaneous-vel
$initFlowStatistics
; 24= Coupled
; /solve/set/p-v-coupling 24

$relax_SIMPLE
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
/file/auto-save/root-name "${outDirPath}/${outDirName}/$dataFileName"

!date

report summary no
$init_iterations

; collect stats?, sampleInt, flow shear?, flow heat?, wall stats?
; solve/set/data-sampling yes $sampleInterval yes no yes
$unsteadyStatInitialization
define/parameters/input-parameters/edit "TimeStepSize"

$timeStep
/solve/dual-time-iterate $num_iterations

!date
/file/write-data ${dataFileName}.dat

;###################################
;######## Report Summary ###########
;###################################
report summary no

;########### Parallel Timer Usage #####################
/parallel/timer/usage

;########## Time Statistics ###########################
report/system/time-stats

;########## System Statistics ###########################
report/system/time-stats

;########## Processor Statistics ###########################
report/system/proc-stats

exit
yes
EOT
#              ^^END Journal File Creation END^^
#####################################################################

#####################################################################
#                     Building Fluent Arguements

fluent_args="-t${tot_cpus} $fluent_args -cnf=$PBS_NODEFILE"

fluent_args="-g -i $journalFile -mpi=$MPI $fluent_args"

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


Outputs:
-----------------
Out Directory = ${outDirPath}/${outDirName}
Data File = ${dataFileName}.dat
Log File = ${dataFileName}.log

|                                     | 
+-------------------------------------+

"

#####################################################################
#                     Running the Job Itself

# make directory to store the solution files
mkdir ${outDirPath}/$outDirName

for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$casePath $TMPDIR"
	ssh $node "cp $PBS_O_WORKDIR/$initDataPath $TMPDIR"
	ssh $node "mv $PBS_O_WORKDIR/$journalFile $TMPDIR"
done

cd $TMPDIR

# Launch outfile copying
(while [ 1 ]
do
    myarray=(`find ./ -maxdepth 2 -name "*.out"`)
    if [ ${#myarray[@]} -gt 0 ]; then 
        sleep 30
        filename=$myarray
        cp -u $filename $outDirPath/$outDirName/${filename%.out}_${jobid_num}.out
    fi
done) &
SUBSHELL_PID=$!                 # Get the PID of the backgrounded subshell
echo $SUBSHELL_PID

# Launch fluent
fluent $fluentType $fluent_args > $outFilePath

kill $SUBSHELL_PID

for filename in *.out
do 
    mv $filename ${filename%.out}_${jobid_num}.out
done

for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $TMPDIR/* $outDirPath/$outDirName"
done
cp  $outFilePath $PBS_O_WORKDIR/
cp -r $outDirPath/$outDirName $PBS_O_WORKDIR/

