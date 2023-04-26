#!/bin/bash

export PATH=/usr/local/bin

# 1 for test
# 0 for production
if [[ $1 == "NODEBUG "]]; then
    DEBUG=0
else
    DEBUG=1
fi

# Installomator Label
label="figma"

scriptDir=$(dirname ${0:A})
repoDir=$(dirname $scriptDir)

if [[ $DEBUG == 1 ]]; then
    installomator="