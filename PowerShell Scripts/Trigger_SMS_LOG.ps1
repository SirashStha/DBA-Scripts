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
    INSERT INTO dbo.SMS_LOG(BR_CODE, SMS_SERVICE_TYPE_CODE, MOBILE_NO, SMS_FROM_TO, AC_NO, C_E_CODE, MESSAGE_TEXT, SMS_DATE, SMS_USER_ID, SMS_SUCCESS, SMS_SUCCESS_TIME, ERROR_DESC, VCH_NO, SCREEN_CODE, TR_TO_CUSTOMER_CODE, TR_TO_AC_NO, TR_TO_PRODUCT_CODE, TR_AMT, INCOMING_SMSSTAMP)
    SELECT TOP 1 'AAA', SMS_SERVICE_TYPE_CODE, MOBILE_NO, SMS_FROM_TO, AC_NO, C_E_CODE, MESSAGE_TEXT, SMS_DATE, SMS_USER_ID, SMS_SUCCESS, SMS_SUCCESS_TIME, ERROR_DESC, VCH_NO, SCREEN_CODE, TR_TO_CUSTOMER_CODE, TR_TO_AC_NO, TR_TO_PRODUCT_CODE, TR_AMT, INCOMING_SMSSTAMP
    FROM dbo.SMS_LOG
    WHERE SMS_SUCCESS = 0
"@

# Loop through each server configuration and execute the trigger script
foreach ($server in $servers) {
    $serverName = $server.ServerName
    $userName = $server.UserName
    $password = $server.Password

    foreach ($db in $server.Databases) {
        $database = $db.Database
        
        $connectionString = "Server=$serverName;Database=$database;User ID=$userName;Password=$password;"

        Write-Host "Creating trigger in $serverName - $database"

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
