# Define the central configuration server connection details
$centralServer = "172.30.1.103\SQL2017STD"
$centralDatabase = "COMM_DB_ARJAN"
$centralUser = "sa"
$centralPassword = "!nf0_db17Srv_002"

# Query to fetch the server configurations
$configQuery = "SELECT DATASOURCE 'ServerName', [DB_NAME] 'DatabaseName', DB_USER_ID 'UserName', DB_USER_PW 'Password', SMS_CLIENT_ID 'SMS'
                FROM CLIENT_MAST
                WHERE ISNULL(SMS_CLIENT_ID,'')<>''
               "

# Connection string for the central configuration server
$centralConnectionString = "Server=$centralServer;Database=$centralDatabase;User ID=$centralUser;Password=$centralPassword;"

# Fetch the server configurations
$centralSqlConnection = New-Object System.Data.SqlClient.SqlConnection
$centralSqlConnection.ConnectionString = $centralConnectionString

$centralSqlCommand = $centralSqlConnection.CreateCommand()
$centralSqlCommand.CommandText = $configQuery

$centralSqlConnection.Open()

$centralSqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$centralSqlAdapter.SelectCommand = $centralSqlCommand

$configDataTable = New-Object System.Data.DataTable
$centralSqlAdapter.Fill($configDataTable)

$centralSqlConnection.Close()

# Loop through each server configuration and export the data to CSV
foreach ($row in $configDataTable.Rows) {
    $serverName = $row.ServerName
    $userName = $row.UserName
    $password = $row.Password
    $sms = $row.SMS
    $database = $row.DatabaseName
    $outputFile = "C:\CustomerEmailReport\SMS\$($database)_Output.csv"

    $query = @"
                SELECT $SMS 'SMS_CLIENT_ID', CONVERT(DATE,LEFT(SMS_DATE,11)) [DATE], SMS_DATE, SMS_SUCCESS_TIME, DATEDIFF(SECOND, SMS_DATE, SMS_SUCCESS_TIME)  [DELAY IN SEC]
                FROM SMS_LOG
                WHERE SMS_DATE >= '2025-01-08' AND ISNULL(SMS_SUCCESS_TIME,'')<>'' 
"@

    $connectionString = "Server=$serverName;Database=$database;User ID=$userName;Password=$password;"

    Write-Output "Exporting data from $serverName - $database to $outputFile"

    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
    $sqlConnection.ConnectionString = $connectionString

    $sqlCommand = $sqlConnection.CreateCommand()
    $sqlCommand.CommandText = $query

    $sqlConnection.Open()

    $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $sqlAdapter.SelectCommand = $sqlCommand

    $dataTable = New-Object System.Data.DataTable
    $sqlAdapter.Fill($dataTable)

    $sqlConnection.Close()

    # Skip if no data is found
    if ($dataTable.Rows.Count -eq 0) {
        Write-Host "No data found for $serverName - $database. Skipping export." -ForegroundColor Yellow
        continue
    }

    # Insert an empty line after date change
    $sortedData = $dataTable | Sort-Object DATE
    $outputData = @()
    $previousDate = $null

    foreach ($row in $sortedData) {
        if ($previousDate -ne $null -and $previousDate -ne $row.DATE) {
            $outputData += ""
        }
        $outputData += ($row | ConvertTo-Csv -NoTypeInformation -Delimiter ',')[-1]
        $previousDate = $row.DATE
    }

    # Write headers and data to CSV
    $headers = ($dataTable | ConvertTo-Csv -NoTypeInformation -Delimiter ',')[0]
    $headers | Out-File -FilePath $outputFile -Encoding UTF8
    $outputData | Out-File -FilePath $outputFile -Append -Encoding UTF8

    Write-Host "Data exported successfully to $outputFile" -ForegroundColor Green
}
