#!/bin/bash

# Define paths
LOCAL_DB_PATH="instance/flaskr.sqlite"
REMOTE_DB_PATH="/home/<username>/flaskApp/SeniorDesignLab3Repo/SeniorDesignLab3/instance/flaskr.sqlite"
REMOTE_HOST="<your-pythonanywhere-NickFloyd>@ssh.pythonanywhere.com"

# Check if the local database exists
if [ ! -f "$LOCAL_DB_PATH" ]; then
    echo "Error: Local database file not found at $LOCAL_DB_PATH."
    exit 1
fi

# Securely upload the database to the web server
scp "$LOCAL_DB_PATH" "$REMOTE_HOST:$REMOTE_DB_PATH"

if [ $? -eq 0 ]; then
    echo "Database successfully uploaded to the web server."
else
    echo "Error: Failed to upload the database."
    exit 1
fi
