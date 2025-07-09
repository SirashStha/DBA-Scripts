import os
import pyodbc
import pandas as pd
from datetime import datetime

# List of servers with their connection details
servers = [
    {'server': '172.24.1.182', 'username': 'sa', 'password': '!nf0@DB_Mirmire_SQL'},
    # {'server': '192.168.50.44', 'username': 'sa', 'password': 'infodev'}
    # {'server': '192.168.20.65', 'username': 'sa', 'password': 'infodev'},
    # Add more servers as needed
]

# SQL query to check SQL Server Agent jobs
check_jobs_query = """
WITH LastRun AS (
    SELECT
        job_id,
        MAX(instance_id) AS last_instance_id
    FROM
        msdb.dbo.sysjobhistory
    WHERE
        step_id = 0
    GROUP BY
        job_id
)
SELECT 
    j.name AS [JobName], 
    j.enabled AS [Is_Enabled], 
    s.last_run_outcome AS [Last_Run_Outcome], 
    ISNULL(NULLIF((CONCAT(SUBSTRING(CAST(s.last_run_date AS varchar(8)), 1, 4), '-', SUBSTRING(CAST(s.last_run_date AS varchar(8)), 5, 2), '-', SUBSTRING(CAST(s.last_run_date AS varchar(8)), 7, 2)) ),'0--'),'') AS [Last_Run_Date],
    STUFF(STUFF(RIGHT('000000' + CAST(s.last_run_time AS varchar(50)), 6), 3, 0, ':'), 6, 0, ':') AS [Last_Run_Time],
    st.database_name AS [Dbname],
    @@SERVERNAME AS [ServerName],
	STUFF(STUFF(RIGHT('000000' + CAST(h.run_duration AS varchar(50)), 6), 3, 0, ':'), 6, 0, ':') AS [Run_Duration],
    ((h.run_duration / 10000 * 3600) + ((h.run_duration / 100) % 100 * 60) + (h.run_duration % 100)) AS [Run_Duration_Seconds],
    h.message
FROM msdb.dbo.sysjobs AS j
JOIN msdb.dbo.sysjobservers AS s ON j.job_id = s.job_id
JOIN msdb.dbo.sysjobsteps AS st ON j.job_id = st.job_id
JOIN LastRun lr ON j.job_id = lr.job_id
JOIN msdb.dbo.sysjobhistory AS h ON lr.job_id = h.job_id AND lr.last_instance_id = h.instance_id
WHERE j.enabled = 1 AND s.last_run_outcome = 1 AND s.last_run_date <> ''
GROUP BY j.name, j.enabled, s.last_run_outcome, s.last_run_date, s.last_run_time, st.database_name, h.run_duration, h.message;
"""

# DataFrame to store results
all_jobs = pd.DataFrame(columns=["ServerName", "Dbname", "JobName", "Is_Enabled", "Last_Run_Outcome", "Last_Run_Date", "Last_Run_Time","Run_Duration","Job_History" ])

def check_jobs_on_database(server):
    try:
        conn = pyodbc.connect(
            'DRIVER={ODBC Driver 17 for SQL Server};'
            f'SERVER={server["server"]};'
            f'DATABASE=master;'
            f'UID={server["username"]};'
            f'PWD={server["password"]}'
        )
        cursor = conn.cursor()
        cursor.execute(check_jobs_query)
        
        jobs = cursor.fetchall()
        if jobs:
            for job in jobs:
                # Convert Last_Run_Outcome to "Success" or "Failed"
                last_run_outcome = "Success" if job.Last_Run_Outcome == 1 else "Failed"
                is_enabled = "Yes" if job.Is_Enabled == 1 else "No"
                job_details = {
                    "ServerName": job.ServerName,
                    "Dbname": job.Dbname,
                    "JobName": job.JobName,
                    "Is_Enabled": is_enabled,
                    "Last_Run_Outcome": last_run_outcome,
                    "Last_Run_Date": job.Last_Run_Date,
                    "Last_Run_Time": job.Last_Run_Time,
                    "Run_Duration" : job.Run_Duration,
                    "Job_History"  : job.message
                }
                all_jobs.loc[len(all_jobs)] = job_details
        
        conn.close()
    except Exception as e:
        print(f"Error connecting to {server['server']}: {e}")

# Check jobs on all databases on all servers
for server in servers:
    check_jobs_on_database(server)

# Specify the directory where you want to save the files
output_directory = "C:\SQL_Server_Jobs"

# Generate filenames based on current datetime
current_datetime = datetime.now().strftime("%Y_%m_%d")
excel_filename = f"job_details_{current_datetime}.xlsx"
csv_filename = f"job_details_{current_datetime}.csv"

# Ensure the directory exists
os.makedirs(output_directory, exist_ok=True)

# Save results to an Excel file
excel_path = os.path.join(output_directory, excel_filename)
all_jobs.to_excel(excel_path, index=False)

# Save results to a CSV file
csv_path = os.path.join(output_directory, csv_filename)
all_jobs.to_csv(csv_path, index=False)

print(f"Job details have been saved to {excel_path} and {csv_path}")
