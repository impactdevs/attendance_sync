-----

# MySQL to API Sync Tool

This Python script provides a simple and efficient way to synchronize attendance records from a MySQL database to an external API. It's designed to run continuously, periodically checking for new records in your database and sending them to a specified API endpoint, then deleting the records from your local database upon successful transmission.

-----

## Features

  * **Configurable Settings:** Easily set up your MySQL connection details, table and column names, API URL, and sync interval through an interactive prompt.
  * **Automatic Syncing:** Continuously monitors your specified MySQL table for new records.
  * **API Integration:** Sends attendance data to your API endpoint using `POST` requests.
  * **Data Deletion:** Automatically deletes records from the MySQL database after successful API transmission, ensuring data integrity and preventing re-sending.
  * **Error Handling:** Includes basic error handling for database connection issues and API request failures.
  * **Persistent Configuration:** Saves your settings to a `config.json` file, so you don't have to re-enter them every time you run the script.

-----

## Requirements

Before you begin, make sure you have the following installed:

  * **Python 3.x**
  * **`mysql-connector-python`**: For connecting to MySQL databases.
  * **`requests`**: For making HTTP requests to your API.

You can install these Python libraries using pip:

```bash
pip install mysql-connector-python requests
```

-----

## How to Use

### 1\. Clone the Repository

First, clone this repository to your local machine:

```bash
git clone https://github.com/impactdevs/attendance_sync.git
cd attendance_sync
```

### 2\. Run the Script

Execute the script from your terminal:

```bash
python sync_data.py
```

### 3\. Configure Settings

The first time you run the script, or if you choose to reconfigure, you'll be prompted to enter your settings:

```
🛠️ Configure your settings:
MySQL host [127.0.0.1]:
MySQL user [root]:
MySQL password: your_mysql_password
MySQL database name: your_database_name
Table name [attendances]: your_table_name
ID column name [id or attendance_id]: your_id_column_name
API URL (e.g., http://127.0.0.1:8000/api/attendances): your_api_endpoint
Sync interval in seconds [60]: 30
✅ Configuration saved.
```

  * **MySQL host**: The IP address or hostname of your MySQL server. (Default: `127.0.0.1`)
  * **MySQL user**: Your MySQL username. (Default: `root`)
  * **MySQL password**: Your MySQL password.
  * **MySQL database name**: The name of the database containing your attendance records.
  * **Table name**: The name of the table that stores attendance data. (Default: `attendances`)
  * **ID column name**: The name of the primary key column in your attendance table. (Default: `id`)
  * **API URL**: The full URL of your API endpoint where attendance data should be sent (e.g., `http://127.0.0.1:8000/api/attendances`).
  * **Sync interval in seconds**: How often (in seconds) the script should check for new records. (Default: `60`)

Your configuration will be saved in a file named `config.json` in the same directory as the script.

### 4\. Running the Sync

Once configured, the script will start syncing:

```
✅ Configuration saved.

✅ Started syncing. Press Ctrl + C to stop.

🔄 [2025-07-14 14:30:00.123456] Checking for new records...
ℹ️ No records found.
⏳ Sleeping 30 seconds...

🔄 [2025-07-14 14:30:30.123456] Checking for new records...
✅ Sent: {'staff_id': 101, 'access_date_and_time': '2025-07-14T10:00:00'}
🗑️ Deleted record ID 1 from DB
⏳ Sleeping 30 seconds...
```

The script will continue to run until you manually stop it.

### 5\. Stopping the Sync

To stop the syncing process, press `Ctrl + C` in your terminal. The script will gracefully shut down:

```
^C
👋 Gracefully stopping sync...
🔒 Database connection closed.
```

-----

## Configuration File (`config.json`)

The script uses a `config.json` file to store your settings. An example `config.json` file looks like this:

```json
{
    "host": "127.0.0.1",
    "user": "root",
    "password": "your_mysql_password",
    "database": "your_database_name",
    "table": "attendances",
    "id_column": "id",
    "api_url": "http://127.0.0.1:8000/api/attendances",
    "interval": 60
}
```

If you need to change your settings later, you can either:

  * Run the script and answer `y` when prompted to reconfigure.
  * Manually edit the `config.json` file.

-----

## Database Table Structure

Your attendance table in MySQL should ideally have at least the following columns:

  * **`id`** (or your specified `id_column`): A unique identifier for each record.
  * **`staff_id`**: The ID of the staff member.
  * **`access_date_and_time`**: A `DATETIME` or `TIMESTAMP` column indicating when the attendance occurred.

For example:

```sql
CREATE TABLE attendances (
    id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT NOT NULL,
    access_date_and_time DATETIME NOT NULL
);
```

-----

## API Endpoint Requirements

Your API endpoint should be set up to receive `POST` requests with a JSON body similar to this:

```json
{
    "staff_id": 123,
    "access_date_and_time": "2025-07-14T10:30:00"
}
```

The API is expected to return a `201 Created` HTTP status code upon successful record creation. Any other status code will be considered an error, and the record will not be deleted from the local database.

-----

## Error Handling

The script includes basic error handling for:

  * **MySQL Connection Errors:** If the script cannot connect to the MySQL database, it will print an error message and exit.
  * **API Request Failures:** If an API request fails (e.g., network issues, invalid URL), it will print a warning and attempt to retry in the next sync interval.
  * **API Response Errors:** If the API returns a status code other than `201`, it will print the error code and response text. The record will not be deleted from the database in this case.

-----