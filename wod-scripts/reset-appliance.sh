#!/bin/bash
# WoD appliance RESET script for WKSHP-OpenWork
# Called by procmail-action.sh to reset a student environment
# Arguments: $1 = student number, $2 = student password

STUDENT_NUM=$1
STUDENT_PWD=$2
CONTAINER_NAME="openwork-student${STUDENT_NUM}"

echo "RESET: Resetting OpenWork environment for student${STUDENT_NUM}"

# Stop and remove the old container
docker rm -f "${CONTAINER_NAME}" 2>/dev/null

# Re-create with fresh state (reuses CREATE logic)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "${SCRIPT_DIR}/create-appliance.sh" "${STUDENT_NUM}" "${STUDENT_PWD}"
