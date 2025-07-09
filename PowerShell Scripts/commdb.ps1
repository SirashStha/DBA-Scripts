# Define the central configuration server connection details
$centralServer = "192.168.20.32"
$centralDatabase = "COMM_DB"
$centralUser = "sa"
$centralPassword = "infodev"

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
    $outputFile = "C:\PowershellExcel\$($database)_Output.csv"

    $query = @"
                SELECT GS.cmp_name, DB_NAME(), MM.CUSTOMER_CODE,CM.EMAIL_ID, '$sms' AS 'SMS_CLIENT_ID' 
                FROM MOBILE_MAST MM 
    		    INNER JOIN CUSTOMER_MAST CM ON MM.CUSTOMER_CODE=CM.CUSTOMER_CODE
                INNER JOIN GLOBAL_SETUP GS ON 1=1
		        WHERE ISNULL(CM.EMAIL_ID,'')<>''
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

    # # Ensure varchar values retain leading zeros
    # #Checks only one column
    # foreach ($row in $dataTable.Rows) {
    #     if ($row["CUSTOMER_CODE"] -match '^\d+$') { # Check if the value is numeric
    #         $row["CUSTOMER_CODE"] = "'" + $row["CUSTOMER_CODE"]
    #     }
    # }

    Checks all columns
    foreach ($column in $dataTable.Columns) {
        if ($column.DataType -eq [System.String]) {
            foreach ($row in $dataTable.Rows) {
                if ($row[$column] -match '^\d+$') { # Check if the value is numeric
                    $row[$column] = "."+$row[$column]
                }
            }
        }
    }

    $sqlConnection.Close()

    # Export the DataTable to CSV
    $dataTable | Export-Csv -Path $outputFile -NoTypeInformation

    Write-Output "Data exported successfully to $outputFile"
}
