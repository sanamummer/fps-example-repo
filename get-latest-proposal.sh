#!/bin/bash
BASE_DIR="out"

PROPOSAL_TYPE="$1"

# Find proposal directories and get the latest one
LATEST_PROPOSAL_DIR=$(ls -1v ${BASE_DIR}/ | grep "^$PROPOSAL_TYPE" | tail -n 1)

LATEST_FILE="${LATEST_PROPOSAL_DIR%.sol}"

# Print the path to the latest proposal artifact json file
echo "${BASE_DIR}/${LATEST_PROPOSAL_DIR}/${LATEST_FILE}.json"
