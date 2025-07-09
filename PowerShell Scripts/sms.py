import os
import pyodbc
import pandas as pd
from datetime import datetime

# Central configuration server connection details
central_server = "192.168.20.32"#"172.30.1.103\\SQL2017STD"
central_database = "COMM_DB"#"COMM_DB_ARJAN"
central_user = "sa"
central_password = "infodev"#"!nf0_db17Srv_002"

# Query to fetch server configurations
config_query = """
    SELECT DATASOURCE AS ServerName, [DB_NAME] AS DatabaseName, DB_USER_ID AS UserName, DB_USER_PW AS Password, SMS_CLIENT_ID AS SMS
    FROM CLIENT_MAST
    WHERE ISNULL(SMS_CLIENT_ID,'') <> ''
"""

# Connect to the central configuration server
def get_server_configurations():
    conn_str = (
        f'DRIVER={{ODBC Driver 17 for SQL Server}};'
        f'SERVER={central_server};'
        f'DATABASE={central_database};'
        f'UID={central_user};'
        f'PWD={central_password}'
    )
    conn = pyodbc.connect(conn_str)
    config_df = pd.read_sql(config_query, conn)
    conn.close()
    return config_df

# Export data from each server to CSV
def export_sms_logs(config_row):
    server_name = config_row['ServerName']
    user_name = config_row['UserName']
    password = config_row['Password']
    database = config_row['DatabaseName']
    output_directory = "D:/"
    os.makedirs(output_directory, exist_ok=True)
    output_file = os.path.join(output_directory, f"{database}_Output.csv")
    
    query = """
        SELECT CONVERT(DATE, LEFT(SMS_DATE, 11)) AS [DATE], SMS_DATE, SMS_SUCCESS_TIME, 
               DATEDIFF(SECOND, SMS_DATE, SMS_SUCCESS_TIME) AS [DELAY IN SEC]
        FROM SMS_LOG
        WHERE SMS_DATE >= '2024-01-08' AND ISNULL(SMS_SUCCESS_TIME, '') <> ''
    """
    
    conn_str = (
        f'DRIVER={{ODBC Driver 17 for SQL Server}};'
        f'SERVER={server_name};'
        f'DATABASE={database};'
        f'UID={user_name};'
        f'PWD={password}'
    )
    
    try:
        conn = pyodbc.connect(conn_str)
        sms_df = pd.read_sql(query, conn)
        conn.close()
        
        # # Ensure numeric CUSTOMER_CODE retains leading zeros if applicable
        # if 'CUSTOMER_CODE' in sms_df.columns:
        #     sms_df['CUSTOMER_CODE'] = sms_df['CUSTOMER_CODE'].astype(str).apply(lambda x: f"'{x}" if x.isdigit() else x)
        
        sms_df.to_csv(output_file, index=False)
        print(f"Data exported successfully to {output_file}")
    except Exception as e:
        print(f"Error exporting data from {server_name} - {database}: {e}")

# Main workflow
configurations = get_server_configurations()
for _, row in configurations.iterrows():
    export_sms_logs(row)
