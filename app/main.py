from fastapi import FastAPI
import os
from dotenv import load_dotenv
import psycopg2

load_dotenv()

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from ECS!"}

@app.get("/db-check")
def db_check():
    try:
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST"),
            database=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            port=5432
        )
        conn.close()
        return {"db": "connected"}
    except Exception as e:
        return {"db_error": str(e)}
