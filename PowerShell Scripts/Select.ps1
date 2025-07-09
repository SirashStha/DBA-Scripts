# Read server configurations from a text file
# The text file should have the following format:
# ServerName,UserName,Password,Database1|Database2|Database3

$serverConfigPath = "D:\Power Shell Scripts\server_config.txt" #ServerName,UserName,Password,Database1|Database2|Database3
$servers = @()

# Read and parse the server configuration file
foreach ($line in Get-Content -Path $serverConfigPath) {
    $parts = $line -split ','
    $databases = $parts[3] -split '\|'

    $servers += @{
        ServerName = $parts[0].Trim()
        UserName = $parts[1].Trim()
        Password = $parts[2].Trim()
        Databases = @()
    }

    foreach ($db in $databases) {
        $servers[-1].Databases += @{ Database = $db.Trim() }
    }
}

# Define the SELECT query
$selectQuery = @"
    SELECT SUBSTRING(DB_NAME(),10,3) ;
"@

# Loop through each server configuration and execute the SELECT query
foreach ($server in $servers) {
    $serverName = $server.ServerName
    $userName = $server.UserName
    $password = $server.Password

    foreach ($db in $server.Databases) {
        $database = $db.Database
        $connectionString = "Server=$serverName;Database=$database;User ID=$userName;Password=$password;"

        Write-Host "Running SELECT query on $serverName - $database"

        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $sqlConnection.ConnectionString = $connectionString

        $sqlCommand = $sqlConnection.CreateCommand()
        $sqlCommand.CommandText = $selectQuery

        try {
            $sqlConnection.Open()
            $sqlReader = $sqlCommand.ExecuteReader()

            while ($sqlReader.Read()) {
                $row = ""
                for ($i = 0; $i -lt $sqlReader.FieldCount; $i++) {
                    $row += "$($sqlReader.GetName($i)): $($sqlReader.GetValue($i))  "
                }
                Write-Host $row
            }
            $sqlReader.Close()

            Write-Host "Query executed successfully on $serverName - $database" -ForegroundColor Green
            Write-Host " "
        } catch {
            Write-Host "Failed to execute query on $serverName - $database. Error: $_" -ForegroundColor Red
        } finally {
            $sqlConnection.Close()
        }
    }
}

Write-Host "SELECT query execution completed for all servers and databases." -ForegroundColor Cyan
