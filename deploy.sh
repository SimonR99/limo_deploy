#!/bin/bash

# Check if arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <user/team_name> <robot_host>"
    echo "Example: $0 equipe204 lm1367"
    exit 1
fi

TEAM_USER=$1
ROBOT_HOST=$2
# Append .local if not present
if [[ "$ROBOT_HOST" != *".local" ]]; then
    REMOTE_HOST="${ROBOT_HOST}.local"
else
    REMOTE_HOST="$ROBOT_HOST"
fi
TARGET="${TEAM_USER}@${REMOTE_HOST}"

echo "Targeting: $TARGET"

# Set up SSH Control Socket for connection sharing
# This allows us to enter the password only once
SOCKET_DIR="/tmp/limo_deploy_sockets"
mkdir -p "$SOCKET_DIR"
# Clean up any stale socket
CONTROL_SOCKET="$SOCKET_DIR/${TEAM_USER}_${REMOTE_HOST}_%p"

echo "Establishing connection (you will be asked for password ONCE)..."
# Start the master connection
# -M: master mode
# -S: socket path
# -f: go to background
# -N: no command
# -T: disable pseudo-tty
ssh -M -S "$CONTROL_SOCKET" -fnNT "$TARGET"

if [ $? -ne 0 ]; then
    echo "Failed to establish connection."
    exit 1
fi

# Ensure the connection closes when the script exits
trap "echo 'Closing connection...'; ssh -S '$CONTROL_SOCKET' -O exit '$TARGET' 2>/dev/null" EXIT

# 1. Clean remote home directory
# find . -mindepth 1 -maxdepth 1 deletes all files/hidden files in cd safely
echo "Cleaning remote directory..."
ssh -S "$CONTROL_SOCKET" "$TARGET" "find . -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -rf"

# 2. Sync fresh_template
echo "Syncing fresh_template..."
# Use -e to specify the ssh command with the socket
rsync -av -e "ssh -S '$CONTROL_SOCKET'" ./fresh_template/ "${TARGET}:/home/${TEAM_USER}/"

# 3. Build workspace
echo "Building workspace..."
ssh -S "$CONTROL_SOCKET" "$TARGET" "source /opt/ros/humble/setup.bash && cd limo_ws && colcon build"

echo "Deployment complete."
