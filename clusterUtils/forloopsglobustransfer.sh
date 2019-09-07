#!/bin/zsh
setopt extendedglob

loginID=$(globus whoami --format unix --jmespath sub)
BrickEndpntID=$(globus endpoint search --filter-scope my-endpoints --format unix --jmespath "DATA[?display_name=='U2berggeistBrick'].id")
BrickCFDshow=$BrickEndpntID:'/~/odrive/Google Drive -Clemson/1. Grad Research/1. CFD Stuff/'
BrickDesign=$BrickEndpntID:'/~/odrive/Google Drive -Clemson/1. Grad Research/1. CFD Stuff/0. Organized Runs/Design_SpaceRuns/'
clusterDesignPath=/common/miller/jrwrigh/DesignSpaceSims
clusterEndpntID=$(globus endpoint search --format unix --jmespath "DATA[?name=='xfer01-ext.clemson.edu'].id" clemson)

# for msh in {p066L0780,p082L0780}
for msh in p082L0780
# for msh in ./p^(125|150|r)*(/)
do
    # echo msh $msh
    cd ${clusterDesignPath}/$msh

    # for swirl in $msh_S*(/)
    # for swirl in S{100,150}
    for swirl in S150
    do
        cd ${msh}_${swirl}/SBES
        brickdirs=$(globus ls --jmespath "DATA[?type=='dir'].name" ${BrickDesign}/${msh}/${msh}_${swirl})

        for simrun in 6*(/)
        do
            # print "\n"
           print "\n" WORKING ON $simrun '=========='
           cd $simrun
           pathsimrun=${msh}/${msh}_${swirl}/${simrun}
           pathsimrunclstr=${msh}/${msh}_${swirl}/SBES/${simrun}
           if echo $brickdirs | grep $simrun ; then
               echo $simrun in BrickDrive

               bricksimruncontent=$(globus ls ${BrickDesign}/${pathsimrun})
               if echo $bricksimruncontent | grep .out ; then
                   echo brick $simrun already has .out file
               else
                   echo brick $simrun does not have .out file
                   myarray=(`find ./ -maxdepth 2 -name "*.out"`)
                   if [ ${#myarray[@]} -gt 0 ]; then 
                       echo cluster $simrun has .out file
                       outfile=$(basename ${myarray[1]})
                       globus transfer --format text ${clusterEndpntID}:${clusterDesignPath}/${pathsimrunclstr}/${outfile} \
                           ${BrickDesign}/${pathsimrun}/${outfile}
                   else 
                       echo cluster $simrun has no .out file
                   fi
               fi

           else
               echo $simrun dir not in BrickDrive
               myarray=(`find ./ -maxdepth 2 -name "*.out"`)
               if [ ${#myarray[@]} -gt 0 ]; then 
                   echo cluster $simrun has .out file
                   outfile=$(basename ${myarray[1]})
                   globus mkdir ${BrickDesign}/${msh}/${msh}_${swirl}/${simrun}/
                   globus transfer --format text ${clusterEndpntID}:${clusterDesignPath}/${pathsimrunclstr}/${outfile} \
                       ${BrickDesign}/${pathsimrun}/${outfile}
                   
               else 
                   echo cluster $simrun has no .out file
               fi
           fi
           cd ../

        done
        cd ../../
    done
cd ../
done

        # # CREATE FLUENT JOB SCRIPTS AND RUN
        # dirname=(*S$var*/SBES/)
        # cd $dirname
        # casename=(*.cas)
        # initdatapath=(`find ../ -maxdepth 3 -name "*SST.dat"`)
        # initdataname=$(basename $initdatapath)
        # ln -s $initdatapath $initdataname
        # mshbase=$(basename $msh)

        # # QSUB IF CDAT FILE IS NOT PRESENT
        # dirname=(*S$var*/SST/)
        # cd $dirname
        # myarray=(`find ./ -maxdepth 2 -name "*.cdat"`)
        # if [ ${#myarray[@]} -gt 0 ]; then 
        #     print has data
        # else 
        #     print doesnt have data
        #     # qsub fluentSST.sh
        # fi
        # cd ../../

