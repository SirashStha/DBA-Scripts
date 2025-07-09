# Define the central configuration server connection details
$centralServer = "172.30.1.103"
$centralDatabase = "COMM_DB_ARJAN"
$centralUser = "shirash"
$centralPassword = "Sh!rash@123"

# Query to fetch the server configurations
$configQuery = @"
SELECT 
    DATASOURCE AS ServerName, 
    [DB_NAME] AS DatabaseName, 
    DB_USER_ID AS UserName, 
    DB_USER_PW AS Password, 
    SMS_CLIENT_ID AS SMS, 
    CLIENT_ID AS ClientID
FROM CLIENT_MAST
"@

# Connection string for the central configuration server
$centralConnectionString = "Server=$centralServer;Database=$centralDatabase;User ID=$centralUser;Password=$centralPassword;"

# Fetch the server configurations
$centralSqlConnection = New-Object System.Data.SqlClient.SqlConnection $centralConnectionString
$centralSqlCommand = $centralSqlConnection.CreateCommand()
$centralSqlCommand.CommandText = $configQuery

$centralSqlConnection.Open()
$centralSqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $centralSqlCommand
$configDataTable = New-Object System.Data.DataTable
$centralSqlAdapter.Fill($configDataTable)
$centralSqlConnection.Close()

# Output path
$outputFile = "C:\Powershell\CID_TRAN_ID_0_Output.csv"

# Create a list to store all data rows
$allData = New-Object System.Collections.Generic.List[System.Data.DataRow]

# Loop through each server configuration and collect the data
foreach ($row in $configDataTable.Rows) {
    $serverName = $row.ServerName
    $userName = $row.UserName
    $password = $row.Password
    $database = $row.DatabaseName
    $clientId = $row.ClientID

    $query = @"
SELECT '$clientId' AS CLIENT_ID, COUNT(*) AS CNT
FROM dbo.CUSTOMER_IDENTITY_DOC d
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.CUSTOMER_IDENTITY i
    WHERE i.TRAN_ID = d.CUSTOMER_IDENTITY_ID
)
"@

    $connectionString = "Server=$serverName;Database=$database;User ID=$userName;Password=$password;"
    Write-Output "Exporting data from $serverName - $database"

    try {
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $sqlCommand = $sqlConnection.CreateCommand()
        $sqlCommand.CommandText = $query

        $sqlConnection.Open()
        $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $sqlCommand
        $dataTable = New-Object System.Data.DataTable
        $sqlAdapter.Fill($dataTable)
        $sqlConnection.Close()

        # Format numeric strings (if needed)
        foreach ($column in $dataTable.Columns) {
            if ($column.DataType -eq [System.String]) {
                foreach ($r in $dataTable.Rows) {
                    if ($r[$column] -match '^\d+$') {
                        $r[$column] = "``" + $r[$column]
                    }
                }
            }
        }

        # Add rows where CNT is not 0
        foreach ($r in $dataTable.Rows) {
            if ($r["CNT"] -ne 0) {
                $allData.Add($r)
            }
        }

    } catch {
        Write-Warning "Error processing $serverName - ${database}: $_"
    }
}

# If data exists, sort and export
if ($allData.Count -gt 0) {
    $finalTable = $allData[0].Table.Clone()  # Clone structure

    foreach ($r in $allData | Sort-Object CLIENT_ID) {
        $finalTable.ImportRow($r)
    }

    # Export to CSV
    $finalTable | Export-Csv -Path $outputFile -NoTypeInformation
    Write-Output "✅ Data exported successfully to $outputFile"
} else {
    Write-Output "⚠️ No data to export."
}
