CREATE OR ALTER PROC USP_READ_AUDIT_LOGS (@FOLDER_PATH VARCHAR(1000))
AS
BEGIN

	IF @FOLDER_PATH <> ''
	BEGIN
		SET @FOLDER_PATH = CONCAT(@FOLDER_PATH,'\')
	END

	DECLARE @folderPath NVARCHAR(255) = 'Z:\SQL-Audit-Log\'+@FOLDER_PATH;
	--DECLARE @folderPath NVARCHAR(255) = @FOLDER_PATH;

	DECLARE @filePath NVARCHAR(255);
	DECLARE @cmd NVARCHAR(4000);
	DECLARE @result TABLE (
		EventTime DATETIME,
		ServerPrincipalName NVARCHAR(255),
		DatabaseName NVARCHAR(255),
		ActionId NVARCHAR(255),
		Succeeded BIT,
		Statement NVARCHAR(MAX),
		FilePath NVARCHAR(4000)
	);

	-- Temporary table to store file names
	CREATE TABLE #FileList (FileName NVARCHAR(255));

	-- List all .sqlaudit files in the folder and subfolders
	SET @cmd = 'dir "' + @folderPath + '*.sqlaudit" /b /s';
	INSERT INTO #FileList
	EXEC xp_cmdshell @cmd;

	-- Loop through each file and read the audit logs
	DECLARE @file NVARCHAR(255);
	DECLARE @folderName NVARCHAR(500);


	DECLARE file_cursor CURSOR FOR 
	SELECT FileName FROM #FileList WHERE FileName IS NOT NULL;

	OPEN file_cursor;
	FETCH NEXT FROM file_cursor INTO @file;

	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @folderName = LEFT(@file, LEN(@file) - CHARINDEX('\', REVERSE(@file)));

		-- Read the audit logs from each file and adjust the event_time for server time
		INSERT INTO @result (EventTime, ServerPrincipalName, DatabaseName, ActionId, Succeeded, Statement, FilePath)
		SELECT 
			DATEADD(MINUTE, 330, event_time) AS EventTime,  -- Adjust for IST (UTC+5:30)
			server_principal_name,
			database_name,
			action_id,
			succeeded,
			statement,
			@folderName
		FROM sys.fn_get_audit_file(@file, DEFAULT, DEFAULT);

		FETCH NEXT FROM file_cursor INTO @file;
	END

	CLOSE file_cursor;
	DEALLOCATE file_cursor;

	-- Select the consolidated results, excluding entries where ServerPrincipalName is 'sa'
	SELECT *
	FROM @result
	WHERE ActionId <> 'AUSC'
	ORDER BY FilePath, EventTime DESC;

	-- Clean up the temporary table
	DROP TABLE #FileList;
END
GO

EXEC dbo.USP_READ_AUDIT_LOGS @FOLDER_PATH='' -- varchar(1000)
