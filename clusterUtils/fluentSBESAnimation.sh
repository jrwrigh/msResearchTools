#!/bin/bash
#PBS -N PlenumMeshTestSBESAnimationTest
#PBS -l select=3:ncpus=40:mpiprocs=40:mem=32gb:phase=18b
#PBS -l walltime=72:00:00
#PBS -j oe
#PBS -m abe
#PBS -M jrwrigh@g.clemson.edu

module purge
module add ansys/19.0
module add intel/17.0

set echo on 

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

fluentType=3ddp
caseFile=4012869_PlenumMeshTest_SBES2_Animation.cas
initDataFile=4012869_PlenumMeshTest_SBES.dat

dataFilename=PlenumMeshTest_SBES
outFile=SBESTest.log
imgDirName=images

colormapscheme=rw_colormap.scm
colormapfile=blackbody_extended.colormap
fluentcolormap=blkbdy-ext

    # MPI options are [ibmmpi, intel, openmpi, cray]
MPI=intel

############
jobid_num=$(echo $PBS_JOBID | grep -Eo "[0-9]{3,}")
echo "jobid_num: $jobid_num"
outFilePath="$PBS_O_WORKDIR/${jobid_num}_${outFile}"
dataFilename=${jobid_num}_${dataFilename}.dat
imgDirName=${jobid_num}_${imgDirName}

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
; 24= Coupled
; /solve/set/p-v-coupling 24
define/parameters/input-parameters/edit "TimeStepSize"

5e-6
/define/parameters/input-parameters/edit "rotationalVelocity"

916.7
/solve/monitors/residual/convergence-criteria
.0001
.0001
.0001
.0001




/server/start-server server_info.txt
!date
; #############
; Start Visualization stuff
; #############
(load "rw_colormap.scm")
/file/read-colormap $colormapfile
/display/set/colormap $fluentcolormap
/display/set/contours/filled-contours yes
/display/set/picture/driver png
/display/set/picture/landscape yes
/display/set/picture/use-window-resolution? no
/display/set/picture/x-resolution 1200
/display/set/picture/y-resolution 720
/display/set/picture/color-mode color
/display/set/colors/color-scheme classic
/display/set/colors/background "dark gray"
/display/set/picture/invert-background? no
/surface/plane-point-n-normal zyplane 0 0 0 1 0 0

/display/set/lights/headlight-on? no
/display/set/lights/lights-on? no

/display/set/contours/surfaces zyplane ()
/display/set/contours/coloring no
/display/set/contours/node-values? yes
/display/set/contours/clip-to-range? no
/display/set/windows/scale/alignment bottom
/display/set/windows/text/application? no
/display/set/windows/text/date? no
/display/set/windows/text/visible? yes
/display/set/windows/text/top -0.85

/display/contour density 0.7 2.2
/display/views/restore-view right
/display/views/auto-scale
/display/views/camera/zoom-camera 1.8
/display/views/camera/target 0 0 0.26
/display/save-picture ${imgDirName}/density0.png
/display/contour pressure -30000 80000
/display/views/restore-view right
/display/views/auto-scale
/display/views/camera/zoom-camera 1.8
/display/views/camera/target 0 0 0.26
/display/save-picture ${imgDirName}/pressure0.png

; Make pictures at every timestep
/solve/execute-commands/add-edit command-1 1 "time-step" "/display/contour density 0.7 2.2"
/solve/execute-commands/add-edit command-2 1 "time-step" "/display/views/restore-view right"
/solve/execute-commands/add-edit command-3 1 "time-step" "/display/views/auto-scale"
/solve/execute-commands/add-edit command-4 1 "time-step" "/display/views/camera/zoom-camera 1.8"
/solve/execute-commands/add-edit command-5 1 "time-step" "/display/views/camera/target 0 0 0.26"
/solve/execute-commands/add-edit command-6 1 "time-step" "/display/save-picture ${imgDirName}/density%t.png"
/solve/execute-commands/add-edit command-7 1 "time-step" "/display/contour pressure -35000 80000"
/solve/execute-commands/add-edit command-8 1 "time-step" "/display/views/restore-view right"
/solve/execute-commands/add-edit command-9 1 "time-step" "/display/views/auto-scale"
/solve/execute-commands/add-edit command-10 1 "time-step" "/display/views/camera/zoom-camera 1.8"
/solve/execute-commands/add-edit command-11 1 "time-step" "/display/views/camera/target 0 0 0.26"
/solve/execute-commands/add-edit command-12 1 "time-step" "/display/save-picture ${imgDirName}/pressure%t.png"

/solve/dual-time-iterate 1000

!date
; /parallel/timer/usage
; /file/write-data $dataFilename
exit
yes
EOT

num_nodes=$(cat $PBS_NODEFILE | sort -u | wc -l)
echo "\$num_nodes = " $num_nodes
tot_cpus=$(cat $PBS_NODEFILE | wc -l )
echo "\$tot_cpus = " $tot_cpus

fluent_args="-t${tot_cpus} $fluent_args -cnf=$PBS_NODEFILE"

fluent_args="-i $journalFile -mpi=$MPI $fluent_args"

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
Data File = $dataFilename
Log File = $outFile

|                           | 
+---------------------------+

"

for node in `uniq $PBS_NODEFILE`
do
	ssh $node "cp $PBS_O_WORKDIR/$caseFile $TMPDIR"
	ssh $node "cp $PBS_O_WORKDIR/$initDataFile $TMPDIR"
	ssh $node "cp $PBS_O_WORKDIR/$colormapscheme $TMPDIR"
	ssh $node "cp $PBS_O_WORKDIR/$colormapfile $TMPDIR"
	ssh $node "mv $PBS_O_WORKDIR/$journalFile $TMPDIR"
	ssh $node "mkdir $TMPDIR/$imgDirName"
done

cd $TMPDIR

fluent $fluentType $fluent_args > $outFilePath


for node in `uniq $PBS_NODEFILE`
do
    ssh $node "cp -r $TMPDIR/* $PBS_O_WORKDIR"
done



