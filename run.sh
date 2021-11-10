#!/usr/bin/env bash

CUR=$(pwd)
PROGRAM=${CUR##*/}

if [[ $1 == "topo" ]]; then 
    docker run --privileged \
        -v ${CUR}/bmv2.py:/root/bmv2.py \
        --rm -it \
        --name=mn \
        opennetworking/p4mn --topo=topo
elif [[ $1 == "p4r" ]]; then
    docker run --rm \
        -v ${CUR}/p4runtime-client:/PI/p4r-client \
        -v ${CUR}/p4c-out:/PI/p4c-out \
        -w /PI/p4r-client \
        --name=p4r \
        --net=container:mn \
        p4lang/pi \
        python -u mycontroller.py --p4info ../p4c-out/bmv2/${PROGRAM}_p4info.txt \
        --bmv2-json ../p4c-out/bmv2/${PROGRAM}.json
else
    echo "Try to clean previous environment..."
    ./stop.sh
    echo "Setting Pipeline Config..."
    docker run --rm  \
        -v ${CUR}/p4runtime-client:/PI/p4r-client \
        -v ${CUR}/p4c-out:/PI/p4c-out \
        -w /PI/p4r-client \
        --name=p4r \
        p4lang/pi \
        python mycontroller.py --p4info ../p4c-out/bmv2/${PROGRAM}_p4info.txt \
        --bmv2-json ../p4c-out/bmv2/${PROGRAM}.json &
    sleep 0.2
    docker run --privileged \
        --net=container:p4r \
        -v ${CUR}/bmv2.py:/root/bmv2.py \
        --rm -it \
        --name=mn \
        opennetworking/p4mn --topo=topo
fi
