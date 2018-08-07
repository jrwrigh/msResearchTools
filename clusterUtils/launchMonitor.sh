#! /bin/bash

while getopts ":s" options;do
    case $options in
        s)
            justssh=1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;;
    esac
done

ARG=${@:$OPTIND:1}


if [ -n $ARG ]; then
    jobid=$(qstat -u $USER | grep -o "[0-9]\{7\}\.pbs02")
else
    jobid=$ARG
fi

echo "Job ID is: $jobid"
nodes=$(qstat -xf $jobid | grep -o "\(node[0-9]\{4\}\)" | sort --unique)
echo -e "Nodes used in job are:\n$nodes"
echo ""

for node in $nodes;
do
    if [ $(ssh $node "ls /local_scratch/" | grep "pbs") ]; then
        correctnode=$node
    fi
done


if [[$justssh -eq 0]]
then

echo "Monitoring CFX job in " $correctnode

ssh -X $correctnode <<-EOF
module load ansys/19.0

cd /local_scratch/pbs.$jobid

pwd
dir="\$(ls | grep -o "\b.*dir")"
cfx5solve -monitor "\$dir"
EOF

else
    echo "SSH to" $correctnode
ssh -t $correctnode "cd /local_scratch/pbs.$jobid; bash -l"
fi
