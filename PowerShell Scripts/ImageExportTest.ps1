# Define the SQL Server connection details
$serverName = "192.168.50.44"
$databaseName = "INFINITY_020_001"
$username = "sa"
$password = "infodev"

$basePath = "D:\" + $databaseName + "\"

# Define the SQL query to retrieve the image data
$query = 
"   
    SELECT TOP 1 '000' BR_CODE, '000'CUSTOMER_CODE, D.DOC_GUID [FILE_NAME], M.FILE_EXTENSION FILE_EXTENSION, D.DOC_FILE IMG
    FROM COA_TRAN_MAST_DOC M 
		INNER JOIN dbo.DOC_STORE D ON M.DOC_GUID = D.DOC_GUID
"
                    



# Create the SQL connection using SQL Server OLEDB provider
$connectionString = "Server=$serverName;Database=$databaseName;User Id=$username;Password=$password;"
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

# Create a SQL command
$command = $connection.CreateCommand()
$command.CommandText = $query

# Execute the SQL query
$reader = $command.ExecuteReader()

# Iterate through the results
while ($reader.Read()) {
    $brCode = $reader["BR_CODE"]
    $customerCode = $reader["CUSTOMER_CODE"]
    $fileName = $reader["FILE_NAME"]
    $binaryData = $reader["IMG"]
    $fileExtension = $reader["FILE_EXTENSION"]

    # Define the directory where the images will be saved
    $outputDir = $basePath + $brCode + "\" + $customerCode + "\"
    
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory
    }

    # Define the output file path (assuming the images are JPG)
    $outputFile = Join-Path $outputDir "$fileName.$fileExtension"

    # Check if file already exists
    if (Test-Path $outputFile) {
        Write-Host "File already exists, skipping: $outputFile" -ForegroundColor Yellow
    } 
    else {
        # Save the binary data as an image file
        [System.IO.File]::WriteAllBytes($outputFile, $binaryData)
        Write-Host "Saved image for customer: $customerCode" -ForegroundColor Green
    }
}


# Close the connection
$reader.Close()
$connection.Close()

Write-Host "Image export completed!" -ForegroundColor Cyan
