#! /bin/bash
set -e
set -u
usage="
launchMonitor allows you to keep track of a job as it runs. It can launch a 
CFX or Fluent simulation monitor for an ongoing simulation or even launch 
an SSH session to the nodes being used by the job.

Usage: launchMonitor {-f | -c | -s | -h} <JobID>
     Example: launchMonitor -f 4999233
Options:
    -c       Launch a CFX Remote Monitor
    -f       Launch a Fluent Remote Monitor
    -h       Access this help menu
    -s       Launch an SSH Session at the head node
Arguements:
    <JobID>  ID number of the job to be monitored
"

fluent=false
cfx=false
justssh=false

while getopts "scfh" options;do
    case $options in
        f)
            fluent=true
            ;;
        c)
            cfx=true
            ;;
        s)
            justssh=true
            ;;
        h)
            echo "$usage" >&2
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            echo "Usage: launchMonitor {-f | -c | -s | -h} <JobID>"
            exit 1
            ;;
    esac
done
shift "$(($OPTIND -1))"

if $justssh; then
    echo -e 'Scipt will SSH to head node working directory only\n'
elif $cfx; then
    echo -e 'Script will SSH and open CFX Monitor\n'
elif $fluent; then
    echo -e 'Script will SSH and open Fluent Remote Visual\n'
fi

ARG=$*
# echo "ARG is: $ARG"

if [[ -n $ARG ]]; then
    jobid=$ARG
else
    jobid=$(qstat -u $USER | grep -o "[0-9]\{7\}\.pbs02")
fi

if (( $(grep -c . <<<"$jobid") > 1 )); then
    # grep count the number of lines in $jobid
    echo "There is more than one job currently running"
    echo "A specific job ID must be specified"
    echo "Currently jobs are: $jobid"
    exit 1
fi

echo "Job ID is: $jobid"
nodes=$(qstat -xf $jobid | grep -o "\(node[0-9]\{4\}\)" | sort --unique)

echo -e "Nodes used in job are:\n$nodes"
echo 

for node in $nodes;
do
    if [ $(ssh $node "ls /local_scratch/" | grep "pbs") ]; then
        correctnode=$node
        break
    fi
done

# Commands to run the CFX Monitor
# cfxcommands="module load ansys/19.0;
# cd /local_scratch/pbs.$jobid;
# pwd;
# dir="\$(ls | grep -o "\b.*dir")"
# cfx5solve -monitor "\$dir"
# "

# Commands to run the Fluent Remote Visualization
# fluentcommands="module load ansys/19.0;
# module load intel/19.0;
# cd /local_scratch/pbs.$jobid;
# pwd;
# flremote
# "


if $cfx; then 
    echo "Monitoring CFX job in $correctnode"
    cfxcommands="module load ansys/19.0;
    cd /local_scratch/pbs.$jobid;
    pwd;
    dir=\"\$(ls | grep -o "\b.*dir")\"
    cfx5solve -monitor \"\$dir\"
    "
    ssh -X $correctnode $cfxcommands
elif $fluent; then
    echo "Monitoring Fluent job in $correctnode"
    fluentcommands="module load ansys/19.0;
    module load intel/19.0;
    cd /local_scratch/pbs.$jobid;
    pwd;
    flremote
    "
    ssh -X $correctnode $fluentcommands
elif $justssh; then
    echo "SSH to working directory in $correctnode"
    ssh -t $correctnode "cd /local_scratch/pbs.$jobid; bash -l"
fi
