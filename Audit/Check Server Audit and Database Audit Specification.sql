-- Check the state of the server audit
SELECT name, is_state_enabled 
FROM sys.server_audits 
WHERE name LIKE '%_Audit%';

-- Check the state of the database audit specifications
DECLARE @dbName NVARCHAR(255);
DECLARE @sql NVARCHAR(MAX);
DROP TABLE IF EXISTS ##result
CREATE TABLE ##result (
    DatabaseName NVARCHAR(255),
    AuditSpecName NVARCHAR(255),
    IsStateEnabled BIT
);

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
    -- Set up a dynamic SQL to check the state of database audit specifications for the current database
    SET @sql = '
    USE [' + @dbName + '];
    INSERT INTO ##result (DatabaseName, AuditSpecName, IsStateEnabled)
    SELECT ''' + @dbName + ''', name, is_state_enabled 
    FROM sys.database_audit_specifications 
    WHERE name LIKE ''%_AuditSpec%'';';

    -- Execute the dynamic SQL
    EXEC sp_executesql @sql;

    FETCH NEXT FROM db_cursor INTO @dbName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Select results from the temporary table
SELECT *
FROM ##result;
