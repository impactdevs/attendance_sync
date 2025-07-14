#!/bin/bash

SERVICE_NAME="attendance-sync"
SCRIPT_NAME="sync_attendance.py"
LOG_FILE="/var/log/attendance_sync.log"
SCRIPT_PATH="$(pwd)/$SCRIPT_NAME"
USER_NAME="$(whoami)"
VENV_DIR="$(pwd)/venv"

# Check for Python3
PYTHON=$(which python3)
if [ -z "$PYTHON" ]; then
    echo "❌ Python3 not found. Please install Python3."
    exit 1
fi

# Check if python3-venv is installed
if ! $PYTHON -m venv --help &> /dev/null; then
    echo "❌ python3-venv not found. Installing python3-venv..."
    sudo apt update
    sudo apt install -y python3-venv
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install python3-venv"
        exit 1
    fi
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "⏳ Creating virtual environment in $VENV_DIR..."
    $PYTHON -m venv "$VENV_DIR"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to create virtual environment"
        exit 1
    fi
fi

# Activate virtual environment and set PIP_CMD
source "$VENV_DIR/bin/activate"
PIP_CMD="$VENV_DIR/bin/pip"

echo "🔧 Installing/updating Python dependencies in virtual environment..."
$PIP_CMD install --upgrade pip
$PIP_CMD install mysql-connector-python requests

if [ $? -ne 0 ]; then
    echo "❌ Failed to install Python dependencies"
    exit 1
fi

# Path to Python executable in virtual environment
VENV_PYTHON="$VENV_DIR/bin/python3"

echo "🛠️ Creating systemd service..."

# Create systemd service file
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=Attendance Sync Script
After=network.target

[Service]
ExecStart=$VENV_PYTHON $SCRIPT_PATH
Restart=always
User=$USER_NAME
WorkingDirectory=$(pwd)
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "✅ Enabling and starting the $SERVICE_NAME service..."
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

if [ $? -ne 0 ]; then
    echo "❌ Failed to start service. Check journal: journalctl -u $SERVICE_NAME"
    exit 1
fi

echo "🚀 $SERVICE_NAME is now running in the background."
echo "📄 Logs: sudo tail -f $LOG_FILE"