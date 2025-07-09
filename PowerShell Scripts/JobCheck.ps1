# List of servers with their connection details
$servers = @(
    @{server = "172.24.1.182"; username = "sa"; password = "!nf0@DB_Mirmire_SQL"}
    #@{server = "192.168.50.44"; username = "sa"; password = "infodev"}
    # @{server = "192.168.20.65"; username = "sa"; password = "infodev"},
    # Add more servers as needed
)

# SQL query to check SQL Server Agent jobs
$query = @"
SELECT 
    j.name AS [JobName], 
    j.enabled AS [Is_Enabled], 
    s.last_run_outcome AS [Last_Run_Outcome], 
    ISNULL(NULLIF((CONCAT(SUBSTRING(CAST(s.last_run_date AS varchar(8)), 1, 4), '-', SUBSTRING(CAST(s.last_run_date AS varchar(8)), 5, 2), '-', SUBSTRING(CAST(s.last_run_date AS varchar(8)), 7, 2)) ),'0--'),'') AS [Last_Run_Date],
    STUFF(STUFF(RIGHT('000000' + CAST(s.last_run_time AS varchar(50)), 6), 3, 0, ':'), 6, 0, ':') AS [Last_Run_Time],
    st.database_name AS [Dbname],
    @@SERVERNAME AS [ServerName]
FROM 
    msdb.dbo.sysjobs AS j
JOIN 
    msdb.dbo.sysjobservers AS s ON j.job_id = s.job_id
JOIN 
    msdb.dbo.sysjobsteps AS st ON j.job_id = st.job_id
WHERE 
    j.enabled = 1 
    AND s.last_run_outcome = 1
    AND s.last_run_date <> ''
GROUP BY
    j.name, j.enabled, s.last_run_outcome, s.last_run_date, s.last_run_time, st.database_name;
"@

# DataTable to store results
$all_jobs = New-Object System.Data.DataTable
$columns = @("ServerName", "Dbname", "JobName", "Is_Enabled", "Last_Run_Outcome", "Last_Run_Date", "Last_Run_Time")
foreach ($col in $columns) {
    $all_jobs.Columns.Add($col) | Out-Null
}

function Get-SqlConnection($server, $username, $password) {
    $connectionString = "Server=$server;Database=master;User Id=$username;Password=$password;"
    $connection = New-Object System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection
}

function Check-JobsOnDatabase($server) {
    try {
        $connection = Get-SqlConnection -server $server.server -username $server.username -password $server.password
        $connection.Open()
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $reader = $command.ExecuteReader()

        while ($reader.Read()) {
            $lastRunOutcome = if ($reader["Last_Run_Outcome"] -eq 1) { "Success" } else { "Failed" }
            $isEnabled = if ($reader["Is_Enabled"] -eq 1) { "Yes" } else { "No" }

            $jobDetails = @{
                ServerName      = $reader["ServerName"]
                Dbname          = $reader["Dbname"]
                JobName         = $reader["JobName"]
                Is_Enabled      = $isEnabled
                Last_Run_Outcome= $lastRunOutcome
                Last_Run_Date   = $reader["Last_Run_Date"]
                Last_Run_Time   = $reader["Last_Run_Time"]
            }
            $row = $all_jobs.NewRow()
            foreach ($key in $jobDetails.Keys) {
                $row[$key] = $jobDetails[$key]
            }
            $all_jobs.Rows.Add($row)
        }
        $reader.Close()
        $connection.Close()
    } catch {
        Write-Output "Error connecting to $($server.server): $_"
    }
}

# Check jobs on all databases on all servers
foreach ($server in $servers) {
    Check-JobsOnDatabase -server $server
}

# Specify the directory where you want to save the files
$outputDirectory = "C:\CustomerEmailReport"

# Ensure the directory exists
if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

# Generate filenames based on current datetime
$currentDatetime = Get-Date -Format "yyyy_MM_dd"
$excelFilename = "job_details_$currentDatetime.xlsx"
$csvFilename = "job_details_$currentDatetime.csv"

# Save results to an Excel file
#$excelPath = Join-Path -Path $outputDirectory -ChildPath $excelFilename
#$all_jobs | Export-Excel -Path $excelPath -WorkSheetname "JobDetails" -AutoSize

# Save results to a CSV file
$csvPath = Join-Path -Path $outputDirectory -ChildPath $csvFilename
$all_jobs | Export-Csv -Path $csvPath -NoTypeInformation

Write-Output "Job details have been saved to $excelPath and $csvPath"
