# Define the SQL Server connection details
$serverName = "192.168.20.65"
$databaseName = "INFINITY_171_001_01"
$username = "sa"
$password = "infodev"

# SQL query to fetch CUSTOMER_CODE and image binary data
$query = "SELECT top 5000
		cm.CUSTOMER_CODE,cm.FULL_NAME,
		dss.DOC_FILE,
        cpp.FILE_EXTENSION
	FROM CUSTOMER_MAST CM
		inner join CUSTOMER_PHOTO cpp on cpp.CUSTOMER_CODE=cm.CUSTOMER_CODE
		inner join DOC_STORE dss on dss.DOC_GUID=cpp.DOC_GUID"

# Define the directory where the images will be saved temporarily
$outputDir = "C:\test\images\"
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory
}

# Path for the Excel file
$excelFilePath = Join-Path "C:\test\" "ImageList.xlsx"

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

# Create Excel COM object
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$workbook = $excel.Workbooks.Add()
$worksheet = $workbook.Worksheets.Item(1)
$worksheet.Name = "ImageData"

$row = 1
# Set column headers
$worksheet.Cells.Item($row, 1).Value = "Customer Code"
$worksheet.Cells.Item($row, 2).Value = "Full Name"
$worksheet.Cells.Item($row, 3).Value = "Image"

# Iterate through the results
while ($reader.Read()) {
    $customerCode = $reader["CUSTOMER_CODE"]
    $fullName = $reader["FULL_NAME"] -replace '[<>:"/\\|?*]', '' # Clean invalid characters from the file name
    $imageBinaryData = $reader["DOC_FILE"]
    $imageExtension = $reader["FILE_EXTENSION"]

    # Create a memory stream for the image binary data
    $memoryStream = New-Object System.IO.MemoryStream
    $memoryStream.Write($imageBinaryData, 0, $imageBinaryData.Length)
    $memoryStream.Position = 0

    # Define the file name as CUSTOMER_CODE(FULL_NAME).FILE_EXTENSION
    $imageFileName = "${customerCode}(${fullName}).${imageExtension}"
    $imageFilePath = Join-Path $outputDir $imageFileName

    # Save the image to the file system
    $fileStream = [System.IO.File]::Create($imageFilePath)
    $memoryStream.CopyTo($fileStream)
    $fileStream.Close()

    # Write customer code and full name to the Excel file
    $row++
    $worksheet.Cells.Item($row, 1).Value = $customerCode
    $worksheet.Cells.Item($row, 2).Value = $fullName

    # Add image to the Excel cell
    $worksheet.Shapes.AddPicture($imageFilePath, 0, 1, $worksheet.Cells.Item($row, 3).Left, $worksheet.Cells.Item($row, 2).Top, 100, 100) # Adjust width and height as needed
}

# Save the Excel file
$workbook.SaveAs($excelFilePath)
$workbook.Close($true)
$excel.Quit()

# Clean up COM objects
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null

# Close the connection
$reader.Close()
$connection.Close()

Write-Host "Image export completed, images saved in the specified folder with the desired file names, and embedded into Excel!"
