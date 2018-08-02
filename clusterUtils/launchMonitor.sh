#! /bin/bash

if [ $# -lt 1 ]; then
    jobid=$(qstat -u $USER | grep -o "[0-9]\{7\}\.pbs02")
else
    jobid=$1
fi

echo $jobid
nodes=$(qstat -xf $jobid | grep -o "\(node[0-9]\{4\}\)" | sort --unique)
echo $nodes

for node in $nodes;
do
    if [ $(ssh $node "ls /local_scratch/" | grep "pbs") ]; then
        correctnode=$node
    fi
done

echo "SSH to" $correctnode

ssh -X $correctnode <<-EOF
module load ansys/19.0

cd /local_scratch/pbs.$jobid

pwd
dir="\$(ls | grep -o "\b.*dir")"
cfx5solve -monitor "\$dir"
EOF
