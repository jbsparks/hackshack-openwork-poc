#!/bin/bash
# WoD appliance CLEANUP script for WKSHP-OpenWork
# Called by procmail-action.sh when a student's time expires
# Arguments: $1 = student number

STUDENT_NUM=$1
CONTAINER_NAME="openwork-student${STUDENT_NUM}"

echo "CLEANUP: Removing OpenWork environment for student${STUDENT_NUM}"

docker rm -f "${CONTAINER_NAME}" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "CLEANUP: Container ${CONTAINER_NAME} removed"
else
    echo "CLEANUP: Container ${CONTAINER_NAME} was not running"
fi

exit 0
