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

# Define the CREATE TRIGGER script
$script = @"
    ALTER TABLE [dbo].[CUSTOMER_IDENTITY_DOC]
    ADD CONSTRAINT FK_CUSTOMER_IDENTITY_DOC
    FOREIGN KEY ([CUSTOMER_IDENTITY_ID])
    REFERENCES [dbo].[CUSTOMER_IDENTITY]([TRAN_ID])
"@

# Loop through each server configuration and execute the trigger script
foreach ($server in $servers) {
    $serverName = $server.ServerName
    $userName = $server.UserName
    $password = $server.Password

    foreach ($db in $server.Databases) {
        $database = $db.Database
        
        $connectionString = "Server=$serverName;Database=$database;User ID=$userName;Password=$password;"

        Write-Host "Altering Table in $serverName - $database"

        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $sqlConnection.ConnectionString = $connectionString

        $sqlCommand = $sqlConnection.CreateCommand()
        $sqlCommand.CommandText = $script

        try {
            $sqlConnection.Open()
            $sqlCommand.ExecuteNonQuery()
            Write-Host "Trigger created successfully in $serverName - $database" -ForegroundColor Green
        } catch {
            Write-Host "Failed to create trigger in $serverName - $database. Error: $_" -ForegroundColor Red
        } finally {
            $sqlConnection.Close()
        }
    }
}

Write-Host "Trigger creation completed for all servers and databases." -ForegroundColor Cyan
