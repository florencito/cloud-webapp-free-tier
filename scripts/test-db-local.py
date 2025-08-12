#!/usr/bin/env python3
"""
Local database connection test script.
This script fetches credentials from AWS Secrets Manager and tests the database connection.
"""

import json
import boto3
import psycopg2
from botocore.exceptions import ClientError

def get_secret(secret_arn, region_name="us-east-1"):
    """Retrieve secret from AWS Secrets Manager"""
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_arn)
        secret = get_secret_value_response['SecretString']
        return json.loads(secret)
    except ClientError as e:
        print(f"Error retrieving secret: {e}")
        raise e

def test_db_connection(secret_arn):
    """Test database connection using credentials from Secrets Manager"""
    try:
        # Get credentials from Secrets Manager
        credentials = get_secret(secret_arn)
        print(f"Successfully retrieved credentials for host: {credentials.get('host')}")
        
        # Test database connection
        conn = psycopg2.connect(
            host=credentials.get('host'),
            database=credentials.get('dbname'),
            user=credentials.get('username'),
            password=credentials.get('password'),
            port=credentials.get('port', 5432)
        )
        
        # Test a simple query
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()
        print(f"Database connection successful!")
        print(f"PostgreSQL version: {version[0]}")
        
        cursor.close()
        conn.close()
        
        return True
        
    except Exception as e:
        print(f"Database connection failed: {e}")
        return False

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) != 2:
        print("Usage: python3 scripts/test-db-local.py <secret-arn>")
        print("Example: python3 scripts/test-db-local.py arn:aws:secretsmanager:us-east-1:123456789012:secret:webapp/rds/credentials-AbCdEf")
        sys.exit(1)
    
    secret_arn = sys.argv[1]
    success = test_db_connection(secret_arn)
    
    if success:
        print("✅ Database test completed successfully!")
    else:
        print("❌ Database test failed!")
        sys.exit(1)
