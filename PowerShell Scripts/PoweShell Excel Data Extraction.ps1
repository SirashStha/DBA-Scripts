# Define the list of servers with their corresponding databases and tables
$servers = @(
    @{ ServerName = "172.24.1.133\SQL2017STD"; UserName = "sa"; Password = "!nf0_db17Srv_012"; Databases = @( @{ Database = "INFINITY_042_001" } )}, 
    @{ ServerName = "172.24.1.155\SQL2019ENT"; UserName = "sa"; Password = "!nf0_db17Srv_013"; Databases = @( @{ Database = "INFINITY_067_001" } )},   
    
)

# Loop through each server configuration and export the data to CSV
foreach ($server in $servers) {
    $serverName = $server.ServerName
    $userName = $server.UserName
    $password = $server.Password

    foreach ($db in $server.Databases) {
        $database = $db.Database
        $table = $db.Table
        $outputFile = "C:\CustomerEmailReport\$($database)_$($table)_Output.csv"

        $query = "
                    SELECT DT.* 
                    FROM DT_SCHEDULE DT
                    INNER JOIN DEPOSIT_AC_MAST DAM ON DT.BR_CODE=DAM.BR_CODE AND DT.AC_NO=DAM.AC_NO AND DT.SCH_VS_NO=DAM.SCH_VS_NO
                    WHERE DAM.AC_STATUS<>'03' AND DUE_EDATE='2025-04-13' AND DUE_NDATE='2081/12/30'
 "
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
                        $row[$column] = $row[$column].ToString()
                    }
                }
            }
        }

        $sqlConnection.Close()

        # Create a new DataTable with all columns as text
        $newDataTable = New-Object System.Data.DataTable
        foreach ($column in $dataTable.Columns) {
            $newColumn = New-Object System.Data.DataColumn $column.ColumnName, ([System.String])
            $newDataTable.Columns.Add($newColumn)
        }

        foreach ($row in $dataTable.Rows) {
            $newRow = $newDataTable.NewRow()
            foreach ($column in $dataTable.Columns) {
                $newRow[$column.ColumnName] = "'" + $row[$column.ColumnName]
            }
            $newDataTable.Rows.Add($newRow)
        }

        # Export the new DataTable to CSV
        $newDataTable | Export-Csv -Path $outputFile -NoTypeInformation

        Write-Output "Data exported successfully to $outputFile"
    }
}