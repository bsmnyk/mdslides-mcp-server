#!/bin/bash

# --- Configuration ---
IMAGE_NAME="mdslides-mcp-server"
TAG="latest"
CONTAINER_NAME="mdslides-mcp-instance"
SOURCE_DIR="src/mdslides_mcp_server"
# OUTPUT_DIR="./mkslides_output" # Host path
CONTAINER_OUTPUT_DIR="/app/mkslides_output" # Container path
HTTP_INTERNAL_PORT=8080 # HTTP server port
HTTP_HOST_PORT=8080 # Fixed host port for HTTP server
MAX_PORT_RETRIES=5

# --- Calculate Script Hash ---
echo "Calculating hash of deployment script: $0"
SCRIPT_HASH=$(sha256sum "$0" | awk '{print $1}')
echo "Deployment script hash: $SCRIPT_HASH"

# --- Calculate Source Hash ---
echo "Calculating hash of source directory: $SOURCE_DIR"
# Use find, sort, and sha256sum for a stable hash, including Dockerfile and excluding __pycache__
# Calculate hashes of relevant source files
SOURCE_FILE_HASHES=$(find "$SOURCE_DIR" -type d -name '__pycache__' -prune -o -type f -exec sha256sum {} +)

# Calculate hash of Dockerfile
DOCKERFILE_HASH=$(sha256sum Dockerfile)

# Combine the hashes, sort them for stability, and calculate a final hash
# Sorting ensures that the order of files doesn't affect the final hash
SOURCE_HASH=$( (echo "$SOURCE_FILE_HASHES"; echo "$DOCKERFILE_HASH"; echo "$SCRIPT_HASH") | sort | sha256sum | awk '{print $1}' )

echo "Combined source, Dockerfile, and script hash: $SOURCE_HASH"

# --- Get Current Latest Image ID ---
# Use docker inspect to get the full image ID (SHA256) for accurate comparison
LATEST_IMAGE_ID=$(docker inspect --format='{{.Id}}' "$IMAGE_NAME:$TAG" 2>/dev/null)
if [ -z "$LATEST_IMAGE_ID" ]; then
    echo "Image $IMAGE_NAME:$TAG does not exist yet."
else
    echo "Current latest image ID: $LATEST_IMAGE_ID"
fi

# --- Check for Hash-Tagged Image ---
HASH_IMAGE_EXISTS=$(docker images -q "$IMAGE_NAME:$SOURCE_HASH")
if [ -z "$HASH_IMAGE_EXISTS" ]; then
    echo "Image $IMAGE_NAME:$SOURCE_HASH does not exist."
    NEW_IMAGE_BUILT=true
else
    echo "Image $IMAGE_NAME:$SOURCE_HASH already exists."
    NEW_IMAGE_BUILT=false
fi

# --- Build New Image (if needed) ---
if [ "$NEW_IMAGE_BUILT" = true ]; then
    echo "Building new Docker image: $IMAGE_NAME:$SOURCE_HASH and tagging as $IMAGE_NAME:$TAG"
    if ! docker build -t "$IMAGE_NAME:$SOURCE_HASH" -t "$IMAGE_NAME:$TAG" .; then
        echo "Error: Docker image build failed."
        exit 1
    fi
    LATEST_IMAGE_ID=$(docker images -q "$IMAGE_NAME:$TAG") # Get the new latest ID
    echo "New latest image ID: $LATEST_IMAGE_ID"
else
    echo "Skipping image build as $IMAGE_NAME:$SOURCE_HASH already exists."
fi

# --- Check Running Container ---
RUNNING_CONTAINER_ID=$(docker ps -q --filter name="^/${CONTAINER_NAME}$")
RUNNING_IMAGE_ID=""
if [ -n "$RUNNING_CONTAINER_ID" ]; then
    echo "Container $CONTAINER_NAME is running with ID: $RUNNING_CONTAINER_ID"
    RUNNING_IMAGE_ID=$(docker inspect --format='{{.Image}}' "$RUNNING_CONTAINER_ID")
    echo "Running container image ID: $RUNNING_IMAGE_ID"
else
    echo "Container $CONTAINER_NAME is not running."
fi

# --- Determine if Restart Needed ---
RESTART_NEEDED=false
if [ "$NEW_IMAGE_BUILT" = true ]; then
    echo "Restart needed: New image was built."
    RESTART_NEEDED=true
elif [ -z "$RUNNING_CONTAINER_ID" ]; then
    echo "Restart needed: Container is not running."
    RESTART_NEEDED=true
elif [ "$RUNNING_IMAGE_ID" != "$LATEST_IMAGE_ID" ]; then
    echo "Restart needed: Running container image is not the latest."
    RESTART_NEEDED=true
else
    echo "No restart needed: Container is running the latest code."
fi

if [ "$RESTART_NEEDED" = true ]; then
    if [ -n "$RUNNING_CONTAINER_ID" ]; then
        echo "Stopping and removing existing container: $CONTAINER_NAME"
        if ! docker stop "$CONTAINER_NAME"; then
            echo "Warning: Failed to stop container $CONTAINER_NAME. Attempting to remove anyway."
        fi
        if ! docker rm "$CONTAINER_NAME"; then
             echo "Warning: Failed to remove container $CONTAINER_NAME."
        fi
    fi
fi

# --- Check if HTTP_HOST_PORT is available (if Restart Needed) ---
if [ "$RESTART_NEEDED" = true ]; then
    echo "Checking if HTTP host port $HTTP_HOST_PORT is available..."
    if ss -tuln | grep -q ":$HTTP_HOST_PORT "; then
        echo "Error: HTTP host port $HTTP_HOST_PORT is in use. Please free it or update HTTP_HOST_PORT in the script."
        exit 1
    else
        echo "HTTP host port $HTTP_HOST_PORT is available."
    fi
fi

# --- Restart Container (if Restart Needed) ---
if [ "$RESTART_NEEDED" = true ]; then
    echo "Starting new container $CONTAINER_NAME, mapping HTTP port $HTTP_HOST_PORT:$HTTP_INTERNAL_PORT"
    # Ensure the output directory exists on the host
    # mkdir -p "$OUTPUT_DIR"
    if ! docker run -d --rm -i \
        -p "$HTTP_HOST_PORT:$HTTP_INTERNAL_PORT" \
        --name "$CONTAINER_NAME" "$IMAGE_NAME:$TAG"; then
        echo "Error: Failed to start new container $CONTAINER_NAME."
        exit 1
    fi
    echo "Container $CONTAINER_NAME started successfully."
else
    echo "Container is already running the latest code on image ID $LATEST_IMAGE_ID."
fi

exit 0
