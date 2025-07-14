#!/bin/bash

SERVICE_NAME="attendance-sync"
SCRIPT_NAME="sync_attendance.py"
LOG_FILE="/var/log/attendance_sync.log"
SCRIPT_PATH="$(pwd)/$SCRIPT_NAME"
USER_NAME="$(whoami)"
PYTHON=$(which python3)

echo "🔧 Installing Python dependencies..."
pip install --upgrade pip
pip install mysql-connector-python requests

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
sudo systemctl daemon-reexec
sudo systemctl daemon-reload

echo "✅ Enabling and starting the $SERVICE_NAME service..."
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo "🚀 $SERVICE_NAME is now running in the background."
echo "📄 Logs: sudo tail -f $LOG_FILE"
