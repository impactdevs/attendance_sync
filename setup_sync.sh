#!/bin/bash

SERVICE_NAME="attendance-sync"
SCRIPT_NAME="sync_attendance.py"
LOG_FILE="/var/log/attendance_sync.log"
SCRIPT_PATH="$(pwd)/$SCRIPT_NAME"
USER_NAME="$(whoami)"

# Check for Python3
PYTHON=$(which python3)
if [ -z "$PYTHON" ]; then
    echo "❌ Python3 not found. Please install Python3."
    exit 1
fi

# Function to install pip
install_pip() {
    echo "⏳ Installing pip for Python3..."
    if $PYTHON -m ensurepip --upgrade; then
        echo "✅ pip installed successfully"
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y python3-pip
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3-pip
    else
        echo "❌ Could not install pip - unsupported package manager"
        echo "ℹ️ Please manually install pip for Python3"
        exit 1
    fi
}

# Detect pip command
if command -v pip3 &> /dev/null; then
    PIP_CMD="pip3"
elif command -v pip &> /dev/null; then
    PIP_CMD="pip"
elif $PYTHON -m pip --version &> /dev/null; then
    PIP_CMD="$PYTHON -m pip"
else
    install_pip
    # Verify installation after attempting to install
    if command -v pip3 &> /dev/null; then
        PIP_CMD="pip3"
    else
        PIP_CMD="$PYTHON -m pip"
    fi
fi

echo "🔧 Installing/updating Python dependencies..."
$PIP_CMD install --upgrade pip
$PIP_CMD install mysql-connector-python requests

if [ $? -ne 0 ]; then
    echo "❌ Failed to install Python dependencies"
    exit 1
fi

echo "🛠️ Creating systemd service..."

# Create systemd service file
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null <<EOF
[Unit]
Description=Attendance Sync Script
After=network.target

[Service]
ExecStart=$PYTHON $SCRIPT_PATH
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