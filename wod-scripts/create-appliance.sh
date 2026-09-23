#!/bin/bash
# WoD appliance CREATE script for WKSHP-OpenWork
# Called by procmail-action.sh when a student registers
# Arguments: $1 = student number, $2 = student password
#
# Starts a per-student OpenCode container with unique port mapping

STUDENT_NUM=$1
STUDENT_PWD=$2
CONTAINER_NAME="openwork-student${STUDENT_NUM}"
TUTORIAL_PORT=$((8080 + STUDENT_NUM))
OW_PORT=$((5178 + STUDENT_NUM))
IMAGE_NAME="${OPENWORK_IMAGE:-hackshack-openwork:latest}"

echo "CREATE: Starting OpenCode environment for student${STUDENT_NUM} on ports ${TUTORIAL_PORT}/${OW_PORT}"

# Stop any existing container for this student
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# Start the container
docker run -d \
    --name "${CONTAINER_NAME}" \
    --hostname "openwork-${STUDENT_NUM}" \
    -p "${TUTORIAL_PORT}:8080" \
    -p "${OW_PORT}:5178" \
    -e STUDENT_NUM="${STUDENT_NUM}" \
    -e STUDENT_PWD="${STUDENT_PWD}" \
    --memory="2g" \
    --cpus="2" \
    "${IMAGE_NAME}"

if [ $? -eq 0 ]; then
    echo "CREATE: Container ${CONTAINER_NAME} started"

    # Wait for tutorial page (docs-server starts first, then opencode web)
    echo "CREATE: Waiting for tutorial page..."
    for i in $(seq 1 90); do
        if docker exec "${CONTAINER_NAME}" curl -s http://localhost:8080 > /dev/null 2>&1; then
            echo "CREATE: Tutorial page ready at port ${TUTORIAL_PORT}"
            echo "CREATE: OpenCode UI at port ${OW_PORT}"
            exit 0
        fi
        sleep 2
    done

    echo "CREATE: WARNING -- environment may still be starting on ports ${TUTORIAL_PORT}/${OW_PORT}"
    exit 0
else
    echo "CREATE: FAILED to start container for student${STUDENT_NUM}"
    exit 1
fi
