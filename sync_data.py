import mysql.connector
import requests
import time
import json
import os
from datetime import datetime

CONFIG_FILE = 'config.json'

def prompt_config():
    print("🛠️  Configure your settings:")

    config = {
        "host": input("MySQL host [127.0.0.1]: ") or "127.0.0.1",
        "user": input("MySQL user [root]: ") or "root",
        "password": input("MySQL password: "),
        "database": input("MySQL database name: "),
        "table": input("Table name [attendances]: ") or "attendances",
        "id_column": input("ID column name [id or attendance_id]: ") or "id",
        "api_url": input("API URL (e.g. http://127.0.0.1:8000/api/attendances): "),
        "interval": int(input("Sync interval in seconds [60]: ") or 60)
    }

    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=4)
    print("✅ Configuration saved.\n")
    return config

def load_config():
    if os.path.exists(CONFIG_FILE):
        print("📁 Config file found.")

        with open(CONFIG_FILE) as f:
            config = json.load(f)

        answer = input("Do you want to reconfigure settings? [y/N]: ").strip().lower()
        if answer == 'y':
            config = prompt_config()
    else:
        config = prompt_config()

    return config

def get_attendance_records(cursor, table, id_column):
    cursor.execute(f"SELECT {id_column}, staff_id, access_date_and_time FROM {table}")
    return cursor.fetchall()

def delete_record(cursor, conn, table, id_column, record_id):
    cursor.execute(f"DELETE FROM {table} WHERE {id_column} = %s", (record_id,))
    conn.commit()

def send_to_api(record, cursor, conn, config):
    data = {
        'staff_id': record['staff_id'],
        'access_date_and_time': record['access_date_and_time'].isoformat()
    }

    headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
    }

    try:
        response = requests.post(config['api_url'], json=data, headers=headers)

        if response.status_code == 201:
            print(f"✅ Sent: {data}")
            delete_record(cursor, conn, config['table'], config['id_column'], record[config['id_column']])
            print(f"🗑️ Deleted record ID {record[config['id_column']]} from DB")
        else:
            print(f"❌ Error {response.status_code}: {response.text}")
    except requests.exceptions.RequestException as e:
        print(f"⚠️ Request failed: {e}")

def main():
    config = load_config()

    try:
        conn = mysql.connector.connect(
            host=config['host'],
            user=config['user'],
            password=config['password'],
            database=config['database']
        )
        cursor = conn.cursor(dictionary=True)

        print("✅ Started syncing. Press Ctrl + C to stop.\n")

        try:
            while True:
                print(f"🔄 [{datetime.now()}] Checking for new records...")
                records = get_attendance_records(cursor, config['table'], config['id_column'])

                if not records:
                    print("ℹ️ No records found.")
                else:
                    for record in records:
                        send_to_api(record, cursor, conn, config)

                print(f"⏳ Sleeping {config['interval']} seconds...\n")
                time.sleep(config['interval'])

        except KeyboardInterrupt:
            print("\n👋 Gracefully stopping sync...")

    except mysql.connector.Error as err:
        print(f"❌ Database error: {err}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()
            print("🔒 Database connection closed.")

if __name__ == '__main__':
    main()
