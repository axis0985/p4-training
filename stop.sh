#!/usr/bin/env bash

if [ "$(docker ps -q -f name=mn)" ]; then
    docker kill mn
fi
if [ "$(docker ps -q -f name=p4r)" ]; then
    docker kill p4r
fi