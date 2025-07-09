# Define the list of servers with their corresponding databases and tables
$servers = @(
    @{
        ServerName = "192.168.20.159";
        UserName = "sa";
        Password = "infodev";
	SMS="23";
        Databases = @(
            @{ Database = "INFINITY_120_001" },
            @{ Database = "INFINITY_225_001" }
        )
    },
    @{
        ServerName = "192.168.20.105";
        UserName = "sa";
        Password = "infodev";
	SMS="23";
        Databases = @(
            @{ Database = "INFINITY_TEST" },
            @{ Database = "INFINITY_117_001" }
        )
    }
)

# Loop through each server configuration and export the data to CSV
foreach ($server in $servers) {
    $serverName = $server.ServerName
    $userName = $server.UserName
    $password = $server.Password
    $sms = $server.SMS

    foreach ($db in $server.Databases) {
        $database = $db.Database
        $table = $db.Table
        $outputFile = "C:\$($serverName)_$($database)_Output.csv"

        $query = "SELECT DB_NAME() 'DB_NAME', MM.CUSTOMER_CODE,CM.EMAIL_ID, '$sms' AS 'SMS_CLIENT_ID' FROM MOBILE_MAST MM 
		INNER JOIN CUSTOMER_MAST CM ON MM.CUSTOMER_CODE=CM.CUSTOMER_CODE
		WHERE ISNULL(CM.EMAIL_ID,'')<>''"
        
        $connectionString = "Server=$serverName;Database=$database;User ID=$userName;Password=$password;"

        Write-Output "Exporting data from $serverName - $database.$table to $outputFile"

        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $sqlConnection.ConnectionString = $connectionString

        $sqlCommand = $sqlConnection.CreateCommand()
        $sqlCommand.CommandText = $query

        $sqlConnection.Open()

        $sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
        $sqlAdapter.SelectCommand = $sqlCommand

        $dataTable = New-Object System.Data.DataTable
        $sqlAdapter.Fill($dataTable)

        # Ensure varchar values retain leading zeros
        foreach ($column in $dataTable.Columns) {
            if ($column.DataType -eq [System.String]) {
                foreach ($row in $dataTable.Rows) {
                    if ($row[$column] -match '^\d+$') { # Check if the value is numeric
                        $row[$column] = "'" + $row[$column].ToString()
                    }
                }
            }
        }

        $sqlConnection.Close()

        # Export the new DataTable to CSV
        $dataTable | Export-Csv -Path $outputFile -NoTypeInformation

        Write-Output "Data exported successfully to $outputFile"
    }
}
