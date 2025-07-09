# Define the SQL Server connection details
$serverName = "192.168.50.44"
$databaseName = "INFINITY_020_001"
$username = "sa"
$password = "infodev"

$basePath = "D:\" + $databaseName + "\"

# Query to get all branch codes
$branchQuery = "SELECT DISTINCT BR_CODE FROM BRANCH WHERE [INTEGRATED] = 'YES'"

# Create the SQL connection
$connectionString = "Server=$serverName;Database=$databaseName;User Id=$username;Password=$password;"
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

# Get all branch codes
$branchCommand = $connection.CreateCommand()
$branchCommand.CommandText = $branchQuery
$branchReader = $branchCommand.ExecuteReader()
$branchCodes = @()
while ($branchReader.Read()) {
    $branchCodes += $branchReader["BR_CODE"]
}
$branchReader.Close()
foreach ($brCode in $branchCodes) {
    $docCount = 0
    try {
        # Query for images for this branch
        $query = @"
SELECT LEFT(R.CUSTOMER_CODE,3) BR_CODE, R.CUSTOMER_CODE, D.DOC_GUID [FILE_NAME], M.FILE_EXTENTION FILE_EXTENSION, D.DOC_FILE IMG, 'LOAN_UTILIZATION_DOC' TABLE_NAME
FROM LOAN_UTILIZATION_DOC M 
INNER JOIN dbo.DOC_STORE D ON M.DOC_GUID = D.DOC_GUID
INNER JOIN dbo.LOAN_UTILIZATION_TRAN T ON T.TRAN_ID = M.MAST_TRAN_ID
INNER JOIN dbo.AC_HOLDER_MAST AHM ON AHM.BR_CODE = T.BR_CODE AND AHM.AC_NO = T.AC_NO
INNER JOIN dbo.AC_HOLDER_DETL R ON R.AC_HOLDER_MAST_ID = AHM.TRAN_ID
INNER JOIN BRANCH Z ON Z.BR_CODE = LEFT(R.CUSTOMER_CODE,3) AND Z.BR_CODE = '$brCode'
"@

      
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $reader = $command.ExecuteReader()

        while ($reader.Read()) {
            $customerCode = $reader["CUSTOMER_CODE"]
            $binaryData = $reader["IMG"]
            $tableName = $reader["TABLE_NAME"]
            # $fileName = $reader["FILE_NAME"]
            # $fileExtension = $reader["FILE_EXTENSION"]
            $fileName = $reader["BR_CODE"]+"_"+$customerCode+"_"+$reader["FILE_NAME"]

            $outputDir = $basePath + $brCode + "\" + $customerCode + "\"
            if (-not (Test-Path $outputDir)) {
                New-Item -Path $outputDir -ItemType Directory | Out-Null
            }

            $outputFile = Join-Path $outputDir "$fileName" #"$fileName.$fileExtension"

            if (Test-Path $outputFile) {
                Write-Host "File already exists, skipping: $outputFile" -ForegroundColor BLUE
            } else {
                [System.IO.File]::WriteAllBytes($outputFile, $binaryData)
                $docCount++
            }
            
        }
        if ($docCount -gt 0) {
            Write-Host "Saved $docCount images for branch: $brCode" -ForegroundColor Green
        } else {
            Write-Host "No images found for branch: $brCode" -ForegroundColor Yellow
        }
        # Write-Host "Branch :$brCode, $docCount documents exported." -ForegroundColor Green
        $reader.Close()
    } catch {
        Write-Host "Error in table: $tableName, Branch: $brCode, Customer: $customerCode" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}