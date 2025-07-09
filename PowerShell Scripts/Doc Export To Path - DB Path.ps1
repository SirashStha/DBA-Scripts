# SQL Server connection details
$serverName = "192.168.50.44"
$databaseName = "INFINITY_020_001"
$username = "sa"
$password = "infodev"

# Connection string
$connectionString = "Server=$serverName;Database=$databaseName;User Id=$username;Password=$password;"

# Create and open the SQL connection
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

# Get base path from GLOBAL_SETUP
$pathQuery = "SELECT DOC_STORED_LOCATION_PATH FROM GLOBAL_SETUP"
$pathCommand = $connection.CreateCommand()
$pathCommand.CommandText = $pathQuery
$basePath = $pathCommand.ExecuteScalar()

# Ensure basePath ends with \20\
if (-not $basePath.EndsWith("\")) {
    $basePath += "\" + "20" + "\"
}

# Read and split the SQL script file
$sqlFilePath = "D:\New folder\Script.sql"  # <- Change this to your actual script file path
$sqlBatch = Get-Content $sqlFilePath -Raw -Encoding UTF8
$sqlStatements = $sqlBatch -split "(?m)^\s*GO\s*$"

foreach ($sql in $sqlStatements) {
    $sql = $sql.Trim()
    if (-not [string]::IsNullOrWhiteSpace($sql)) {
        $command = $connection.CreateCommand()
        $command.CommandText = $sql

        try {
            $reader = $command.ExecuteReader()

            $recordsToLog = @()

            do {
                while ($reader.Read()) {
                    $brCode = $reader["BR_CODE"]
                    $customerCode = $reader["CUSTOMER_CODE"]
                    $fileName = $reader["FILE_NAME"]
                    $binaryData = $reader["IMG"]
                    $tableName = $reader["TABLE_NAME"]
                    # $fileExtension = $reader["FILE_EXTENSION"]
                    $docGuid = $fileName

                    # Create output directory path
                    $outputDir = Join-Path $basePath "$brCode\$customerCode"
                    if (-not (Test-Path $outputDir)) {
                        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
                    }

                    # Output file path with extension
                    $outputFile = Join-Path $outputDir ("$fileName")

                    # Save file if it does not exist
                    if (-not (Test-Path $outputFile)) {
                        [System.IO.File]::WriteAllBytes($outputFile, $binaryData)
                        Write-Host "Saved image for customer: $customerCode for table: $tableName" -ForegroundColor Green

                        # Store for logging later
                        $recordsToLog += [PSCustomObject]@{
                            BrCode       = $brCode
                            CustomerCode = $customerCode
                            TableName    = $tableName
                            DocGuid      = $docGuid
                        }
                    }
                    else {
                        Write-Host "File already exists, skipping: $outputFile" -ForegroundColor Yellow
                    }
                }
            } while ($reader.NextResult())

            $reader.Close()

            # Now insert logs (after reader is closed)
            foreach ($logEntry in $recordsToLog) {
                $insertCmd = $connection.CreateCommand()
                $insertCmd.CommandText = @"
INSERT INTO ExportedDocumentsLog (BR_CODE, CUSTOMER_CODE, TABLE_NAME, DOC_GUID)
VALUES (@BrCode, @CustomerCode, @TableName, @DocGuid)
"@
                $insertCmd.Parameters.Add("@BrCode", [System.Data.SqlDbType]::Char, 3).Value = $logEntry.BrCode
                $insertCmd.Parameters.Add("@CustomerCode", [System.Data.SqlDbType]::VarChar, 50).Value = $logEntry.CustomerCode
                $insertCmd.Parameters.Add("@TableName", [System.Data.SqlDbType]::VarChar, 100).Value = $logEntry.TableName
                $insertCmd.Parameters.Add("@DocGuid", [System.Data.SqlDbType]::VarChar, 100).Value = $logEntry.DocGuid
                $insertCmd.ExecuteNonQuery()
            }

        }
        catch {
            Write-Warning "Error executing query: $_"
        }
    }
}

# Cleanup
$connection.Close()
Write-Host "Image export completed!" -ForegroundColor Cyan
