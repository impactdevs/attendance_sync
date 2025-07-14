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

# Get Python version (e.g., 3.8, 3.11)
PYTHON_MAJOR_MINOR=$($PYTHON -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")

# Check for venv module and install if missing
echo "📦 Checking for Python virtual environment package..."
if ! $PYTHON -c "import venv" &> /dev/null; then
    echo "📦 Installing Python virtual environment package..."
    if command -v apt-get &> /dev/null; then
        # Try generic package first
        sudo apt-get update
        sudo apt-get install -y python3-venv
        
        # If generic fails and the venv module is still not found, try version-specific
        if ! $PYTHON -c "import venv" &> /dev/null; then
            echo "ℹ️ Generic 'python3-venv' not sufficient. Trying version-specific 'python${PYTHON_MAJOR_MINOR}-venv'..."
            sudo apt-get install -y "python${PYTHON_MAJOR_MINOR}-venv"
        fi

        # Final check after attempted installation
        if ! $PYTHON -c "import venv" &> /dev/null; then
            echo "❌ Could not install virtualenv for Python $PYTHON_MAJOR_MINOR."
            echo "ℹ️ Please manually install python${PYTHON_MAJOR_MINOR}-venv or python3-virtualenv."
            exit 1
        fi
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3-virtualenv
        if ! $PYTHON -c "import venv" &> /dev/null; then
            echo "❌ Could not install virtualenv for Python $PYTHON_MAJOR_MINOR."
            echo "ℹ️ Please manually install python3-virtualenv."
            exit 1
        fi
    else
        echo "❌ Could not install virtualenv - unsupported package manager"
        echo "ℹ️ Please manually install python3-venv or python3-virtualenv"
        exit 1
    fi
    echo "✅ Python virtual environment package installed."
else
    echo "✅ Python virtual environment package found."
fi

# Create virtual environment
echo "🔧 Creating Python virtual environment..."
if [ ! -d "$VENV_DIR" ]; then
    $PYTHON -m venv "$VENV_DIR"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to create virtual environment"
        echo "ℹ️ Ensure 'ensurepip' is available for your Python version."
        exit 1
    fi
    echo "✅ Virtual environment created at $VENV_DIR"
else
    echo "ℹ️ Virtual environment already exists"
fi

# Verify virtual environment structure
if [ ! -f "$VENV_DIR/bin/activate" ]; then
    echo "❌ Virtual environment is incomplete - missing activation script"
    echo "ℹ️ Try removing and recreating: rm -rf $VENV_DIR"
    exit 1
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Install dependencies in virtual environment
echo "📦 Installing Python dependencies in virtual environment..."
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install mysql-connector-python requests

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
ExecStart=$VENV_DIR/bin/python $SCRIPT_PATH
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
echo "💡 Using Python virtual environment at: $VENV_DIR"
