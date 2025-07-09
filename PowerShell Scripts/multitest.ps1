# Define the list of servers with their corresponding databases and tables
$servers = @(
    @{
        ServerName = "192.168.20.159";
        UserName = "sa";
        Password = "infodev";
        Databases = @(
            @{ Database = "INFINITY_120_001"; Table = "CUSTOMER_MAST" },
            @{ Database = "INFINITY_225_001"; Table = "CUSTOMER_MAST" }
        )
    },
    @{
        ServerName = "192.168.20.105";
        UserName = "sa";
        Password = "infodev";
        Databases = @(
            @{ Database = "INFINITY_TEST"; Table = "CUSTOMER_MAST" },
            @{ Database = "INFINITY_117_001"; Table = "CUSTOMER_MAST" }
        )
    }
)

# Loop through each server configuration and export the data to CSV
foreach ($server in $servers) {
    $serverName = $server.ServerName
    $userName = $server.UserName
    $password = $server.Password

    foreach ($db in $server.Databases) {
        $database = $db.Database
        $table = $db.Table
        $outputFile = "C:\$($serverName)_$($database)_$($table)_Output.csv"

        $query = "SELECT * FROM $database.dbo.$table"
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

        $sqlConnection.Close()

        $dataTable | Export-Csv -Path $outputFile -NoTypeInformation

        Write-Output "Data exported successfully to $outputFile"
    }
}
