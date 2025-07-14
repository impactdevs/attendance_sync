
# Attendance Sync Script

This repository contains a Python script to sync attendance records from a MySQL database to a Laravel API, along with setup and configuration files for easy deployment on a Linux server.

---

## Repository Contents

* `sync_data.py` — Python script that reads attendance data from MySQL and posts to your Laravel API, then deletes synced records.
* `config.json` — Configuration file storing database credentials, API URL, table info, and sync interval.
* `setup_sync.sh` — Bash script to install dependencies, create and enable a systemd service to run the sync script continuously in the background.

---

## Prerequisites

* Linux server (Ubuntu, Debian, CentOS, etc.)
* Python 3.7+ installed (`python3` command available)
* MySQL server accessible with correct credentials
* User with sudo privileges to install services and dependencies

---

## Setup & Usage

### 1. Place Files on Your Server

Clone or copy the repository folder containing:

```bash
sync_data.py
config.json
setup_sync.sh
```

---

### 2. Edit `config.json`

Modify `config.json` to match your environment. Example:

```json
{
  "host": "127.0.0.1",
  "user": "your_mysql_user",
  "password": "your_mysql_password",
  "database": "your_database",
  "table": "attendances",
  "id_column": "attendance_id",
  "api_url": "http://127.0.0.1:8000/api/attendances",
  "interval": 60
}
```

* `interval` is the sync frequency in seconds.

---

### 3. Run Setup Script

Make the setup script executable and run it to install dependencies and set up the systemd service:

```bash
chmod +x setup_sync.sh
./setup_sync.sh
```

This script will:

* Install Python dependencies (`mysql-connector-python` and `requests`)
* Create and enable a `systemd` service called `attendance-sync`
* Start the service to run `sync_data.py` continuously in the background
* Log output to `attendance_sync.log` in the script directory

---

### 4. Manage the Service

Check the service status:

```bash
sudo systemctl status attendance-sync
```

View live logs:

```bash
tail -f attendance_sync.log
```

Stop the service:

```bash
sudo systemctl stop attendance-sync
```

Disable autostart on reboot:

```bash
sudo systemctl disable attendance-sync
```

---

## How It Works

* The Python script connects to your MySQL database and fetches attendance records.
* It posts each record as JSON to the Laravel API endpoint configured in `config.json`.
* Successfully posted records are deleted locally.
* The process repeats continuously with a delay defined by `interval`.

---

## Notes

* Ensure your Laravel API endpoint accepts JSON POST requests and returns HTTP status 201 on success.
* Test `sync_data.py` manually before setting up the service to confirm correct behavior.
* You can modify `config.json` anytime; restart the service to apply changes:

```bash
sudo systemctl restart attendance-sync
```

---

## Troubleshooting

* If the service fails to start or behaves unexpectedly, check the logs:

```bash
cat attendance_sync.log
```

* Verify database connectivity and API availability.
* Make sure the system time is synchronized if timestamps matter.

