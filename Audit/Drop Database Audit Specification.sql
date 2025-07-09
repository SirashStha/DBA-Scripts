DECLARE @dbName NVARCHAR(255);
DECLARE @sql NVARCHAR(MAX);
DECLARE @controlBit BIT = 0;  -- Set to 1 to view audit specs, 0 to delete

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
    -- Create a single dynamic query to either view or drop audit specifications
    SET @sql = 'USE [' + @dbName + ']; ' +
               'DECLARE @auditSpecName NVARCHAR(255); ' +  -- Variable to hold audit specification name
               'DECLARE audit_cursor CURSOR FOR ' +  -- Cursor to go through each audit specification
               'SELECT name FROM sys.database_audit_specifications; ' +
               'OPEN audit_cursor; ' +
               'FETCH NEXT FROM audit_cursor INTO @auditSpecName; ' +
               'WHILE @@FETCH_STATUS = 0 ' +
               'BEGIN ' +
                   'IF @controlBit = 1 ' +  -- Check if we want to view
                   'BEGIN ' +
                       'PRINT ''Database: ' + @dbName + ', Audit Specification: '' + @auditSpecName; ' +
                   'END ' +
                   'ELSE IF @controlBit = 0 ' +  -- Check if we want to delete
                   'BEGIN ' +
                       'ALTER DATABASE AUDIT SPECIFICATION [' + @dbName + '_AuditSpec] WITH (STATE = OFF); ' +  -- Disable the audit specification
                       'DROP DATABASE AUDIT SPECIFICATION [' + @dbName + '_AuditSpec]; ' +  -- Drop the audit specification
                       'PRINT ''Dropped database audit specification: '' + @auditSpecName; ' +
                   'END; ' +
                   'FETCH NEXT FROM audit_cursor INTO @auditSpecName; ' +
               'END; ' +
               'CLOSE audit_cursor; ' +
               'DEALLOCATE audit_cursor;';

    -- Execute the combined SQL with the control bit as a parameter
    EXEC sp_executesql @sql, N'@controlBit BIT', @controlBit;

    FETCH NEXT FROM db_cursor INTO @dbName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;
