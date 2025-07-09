DECLARE @BackupDirectory VARCHAR(4000) = 'D:\SQL Server\Backup\TEST'; -- Update with your backup folder
DECLARE @DatabaseName VARCHAR(4000) = 'TEST'; -- Replace with your database name
DECLARE @BackupFileName VARCHAR(4000);
DECLARE @Command NVARCHAR(MAX);

-- Create backup file name with timestamp
SET @BackupFileName = @BackupDirectory + N'\' + @DatabaseName + N'_' + FORMAT(GETDATE(), 'yyyy_MM_dd_HH_mm') + N'.bak';

-- Perform the database backup
SET @Command = N'BACKUP DATABASE [' + @DatabaseName + N'] TO DISK = ''' + @BackupFileName + N'''';
EXEC sp_executesql @Command;

-- Temp table to hold file information
IF OBJECT_ID('tempdb..#BackupFiles') IS NOT NULL
    DROP TABLE #BackupFiles;

CREATE TABLE #BackupFiles (
    FileName VARCHAR(4000)
);

-- Get the list of files in the backup directory
DECLARE @CmdShellCommand VARCHAR(4000);
SELECT @CmdShellCommand = 'dir "'+@BackupDirectory+'\*.bak" /T:C /O:D'
INSERT INTO #BackupFiles (FileName)
EXEC master..xp_cmdshell @CmdShellCommand


-- Remove unwanted rows 
DELETE FROM #BackupFiles
WHERE FileName IS NULL
   OR FileName NOT LIKE '%.bak';

UPDATE #BackupFiles SET FileName = LTRIM(SUBSTRING(FileName, CHARINDEX('TEST_', FileName), LEN(FileName)))


-- Add an IDENTITY column for row numbering
DROP TABLE IF EXISTS #BackupList
;WITH BackupList AS (
    SELECT 
        FileName,
        ROW_NUMBER() OVER (ORDER BY FileName DESC) AS RowNum
    FROM #BackupFiles
)
SELECT * INTO #BackupList FROM BackupList;

SELECT * FROM #BackupList

-- Delete older backups if more than 5 exist
DECLARE @OldFile VARCHAR(4000);
DECLARE backup_cursor CURSOR FOR
SELECT FileName FROM #BackupList WHERE RowNum > 5;


OPEN backup_cursor;
FETCH NEXT FROM backup_cursor INTO @OldFile;

SELECT @OldFile
WHILE @@FETCH_STATUS = 0
BEGIN
     --Delete the file
    SET @CmdShellCommand = 'DEL "' + @BackupDirectory + '\' + @OldFile + '"'

	--SELECT @CmdShellCommand

    EXEC xp_cmdshell @CmdShellCommand;
    FETCH NEXT FROM backup_cursor INTO @OldFile;
END;

CLOSE backup_cursor;
DEALLOCATE backup_cursor;

-- Clean up
IF OBJECT_ID('tempdb..#BackupFiles') IS NOT NULL
    DROP TABLE #BackupFiles;

IF OBJECT_ID('tempdb..#BackupList') IS NOT NULL
    DROP TABLE #BackupList;
