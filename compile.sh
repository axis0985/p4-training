#!/usr/bin/env bash

set -e

SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
OUT_DIR=${SRC_DIR}/p4c-out/bmv2

mkdir -p ${OUT_DIR}
mkdir -p ${OUT_DIR}/graphs

CUR=$(pwd)
PROGRAM=${CUR##*/}
SRC_DIR=${SRC_DIR}/p4src

echo "FROM ${SRC_DIR}..."
echo "## Compiling ${PROGRAM} in ${OUT_DIR}..."

dockerImage=opennetworking/p4c:latest
dockerRun="docker run --rm -w ${SRC_DIR} -v ${SRC_DIR}:${SRC_DIR} -v ${OUT_DIR}:${OUT_DIR} ${dockerImage}"

# Generate BMv2 JSON and P4Info.
(set -x; ${dockerRun} p4c-bm2-ss --arch v1model -o ${OUT_DIR}/${PROGRAM}.json \
        --p4runtime-files ${OUT_DIR}/${PROGRAM}_p4info.txt ${PROGRAM}.p4)
