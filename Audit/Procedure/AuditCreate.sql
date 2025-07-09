CREATE OR ALTER PROC USP_CREATE_ALTER_AUDIT
AS
BEGIN


	---- Run if xp_cmdshell is disabled
	---- Turn on advanced options and configure xp_cmdshell
	--EXEC sp_configure 'show advanced options', '1';
	--RECONFIGURE;
	--EXEC sp_configure 'xp_cmdshell', '1';
	--RECONFIGURE;

	SET NOCOUNT ON;

	-- Define the base folder path where audit logs will be stored
	DECLARE @baseFolderPath NVARCHAR(255) = 'Z:\SQL-Audit-Log\';

	-- Loop through each database and create audit for each
	DECLARE @dbName NVARCHAR(255);
	DECLARE @auditName NVARCHAR(255);
	DECLARE @auditFolder NVARCHAR(255);
	DECLARE @cmd NVARCHAR(4000);
	DECLARE @sql NVARCHAR(MAX);
	DECLARE @result INT;  -- To capture result of xp_cmdshell
	DECLARE @currentMonth NVARCHAR(7) = CONVERT(VARCHAR(7), GETDATE(), 23);  -- YYYYMM format for the current month

	DECLARE @command NVARCHAR(500);
	DECLARE @folderCheck TABLE (output NVARCHAR(255));


	-- Cursor to go through each database
	DECLARE db_cursor CURSOR FOR
	SELECT name 
	FROM sys.databases
	WHERE state_desc = 'ONLINE'  -- Only include online databases
	AND name NOT IN ('master', 'model', 'msdb', 'tempdb');  -- Exclude system databases

	OPEN db_cursor;
	FETCH NEXT FROM db_cursor INTO @dbName;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Set audit name based on database name and current month
		SET @auditName = @dbName + '_Audit';

		-- Set the folder path for this database's audit logs, including the year and month
		SET @auditFolder = @baseFolderPath + @dbName + '\' + @currentMonth;

		-- Check if the audit already exists for this database
		IF NOT EXISTS (
			SELECT * FROM sys.server_audits WHERE name = @auditName
		)
		BEGIN
			-- Create folder for audit logs using xp_cmdshell
			SET @cmd = 'IF NOT EXIST "' + @auditFolder + '" mkdir "' + @auditFolder + '"';
			EXEC @result = xp_cmdshell @cmd;

			-- Create the server audit for this database with the folder for the current month
			SET @sql = '
			CREATE SERVER AUDIT [' + @auditName + ']
			TO FILE (FILEPATH = ''' + @auditFolder + '\\'',
					 MAXSIZE = 0 MB,
					 MAX_FILES = 100,
					 RESERVE_DISK_SPACE = OFF)
			WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE);
			';
			EXEC sp_executesql @sql;

			-- Add server principal filtering (excluding 'sa')
			SET @sql = 'ALTER SERVER AUDIT [' + @auditName + '] WHERE server_principal_name <> ''sa'';';
			EXEC sp_executesql @sql;

			-- Add server principal filtering (excluding 'sa')
			SET @sql = 'ALTER SERVER AUDIT [' + @auditName + '] WHERE server_principal_name <> ''NT AUTHORITY\SYSTEM'';';
			EXEC sp_executesql @sql;	

			-- Enable the newly created server audit
			SET @sql = 'ALTER SERVER AUDIT [' + @auditName + '] WITH (STATE = ON);';
			EXEC sp_executesql @sql;

			PRINT 'Server Audit created for database: ' + @dbName;
		END
    
		-- Build command to check if folder exists
		SET @command = 'IF EXIST "' + @auditFolder + '" (ECHO FolderExists) ELSE (ECHO FolderDoesNotExist)';

		-- Execute the command via xp_cmdshell
		INSERT INTO @folderCheck
		EXEC xp_cmdshell @command;

		-- Check the result
		IF EXISTS (SELECT * FROM @folderCheck WHERE output = 'FolderExists')
		BEGIN
			PRINT 'Audit already exists for database: ' + @dbName + ' - Skipping.';
		END
		ELSE
		BEGIN
				-- Set the folder path for this database's audit logs, including the year and month
			SET @auditFolder = @baseFolderPath + @dbName + '\' + @currentMonth;

			SELECT @auditFolder

			-- Create folder for audit logs using xp_cmdshell
			SET @cmd = 'IF NOT EXIST "' + @auditFolder + '" mkdir "' + @auditFolder + '"';
			EXEC @result = xp_cmdshell @cmd;

			-- Disable server audit
			SET @sql = 'ALTER SERVER AUDIT [' + @auditName + '] WITH (STATE = OFF);';
			EXEC sp_executesql @sql;

			-- Create the server audit for this database with the folder for the current month
			SET @sql = '
			ALTER SERVER AUDIT [' + @auditName + ']
			TO FILE (FILEPATH = ''' + @auditFolder + '\\'',
						MAXSIZE = 0 MB,
						MAX_FILES = 100,
						RESERVE_DISK_SPACE = OFF)
			WITH (QUEUE_DELAY = 1000, ON_FAILURE = CONTINUE);
			';
			EXEC sp_executesql @sql;

			-- Add server principal filtering (excluding 'sa')
			SET @sql = 'ALTER SERVER AUDIT [' + @auditName + '] WHERE server_principal_name <> ''sa'';';
			EXEC sp_executesql @sql;

			-- Enable the newly created server audit
			SET @sql = 'ALTER SERVER AUDIT [' + @auditName + '] WITH (STATE = ON);';
			EXEC sp_executesql @sql;

			PRINT 'Server Audit altered for database: ' + @dbName;
			PRINT 'New path for server audit is: '+ @auditFolder
		END

	

		-- Check if a database audit specification already exists for this database
		SET @sql = '
					USE [' + @dbName + '];
					IF NOT EXISTS (
						SELECT * 
						FROM sys.database_audit_specifications 
						WHERE name = ''' + @dbName + '_AuditSpec''
					)
					BEGIN
						-- Create a Database Audit Specification to track INSERT, UPDATE, DELETE

						CREATE DATABASE AUDIT SPECIFICATION [' + @dbName + '_AuditSpec]
						FOR SERVER AUDIT [' + @auditName + ']
						ADD (INSERT ON DATABASE::[' + @dbName + '] BY [public]),
						ADD (UPDATE ON DATABASE::[' + @dbName + '] BY [public]),
						ADD (DELETE ON DATABASE::[' + @dbName + '] BY [public])
						WITH (STATE = ON);

						PRINT ''Audit specification created for database: ' + @dbName + ''';
						PRINT ''''
					END
					ELSE
					BEGIN
						PRINT ''Audit specification already exists for database: ' + @dbName + ' - Skipping.'';
						PRINT ''''
					END;
					';

		EXEC sp_executesql @sql;


		FETCH NEXT FROM db_cursor INTO @dbName;
	END

	CLOSE db_cursor;
	DEALLOCATE db_cursor;
END
GO

EXEC dbo.USP_CREATE_ALTER_AUDIT  -- varchar(4000)
