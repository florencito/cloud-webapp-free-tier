from fastapi import FastAPI
import os
import json
import psycopg2

app = FastAPI()

def get_db_credentials():
    """Parse database credentials from AWS Secrets Manager JSON"""
    db_credentials_json = os.getenv("DB_CREDENTIALS")
    if db_credentials_json:
        try:
            credentials = json.loads(db_credentials_json)
            return credentials
        except json.JSONDecodeError:
            print("Error parsing DB_CREDENTIALS JSON")
            return None
    return None

@app.get("/")
def read_root():
    return {"message": "Hello from ECS!"}

@app.get("/db-check")
def db_check():
    try:
        credentials = get_db_credentials()
        if not credentials:
            return {"db_error": "No database credentials found"}
        
        conn = psycopg2.connect(
            host=credentials.get("host"),
            database=credentials.get("dbname"),
            user=credentials.get("username"),
            password=credentials.get("password"),
            port=credentials.get("port", 5432)
        )
        conn.close()
        return {"db": "connected", "host": credentials.get("host")}
    except Exception as e:
        return {"db_error": str(e)}
