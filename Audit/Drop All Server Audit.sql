DECLARE @auditName NVARCHAR(255);
DECLARE @sql NVARCHAR(MAX);

-- Cursor to go through each server audit
DECLARE audit_cursor CURSOR FOR
SELECT name 
FROM sys.server_audits;

OPEN audit_cursor;
FETCH NEXT FROM audit_cursor INTO @auditName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Disable the server audit if it exists
    IF EXISTS (
        SELECT * 
        FROM sys.server_audits 
        WHERE name = @auditName
    )
    BEGIN
        SET @sql = 'ALTER SERVER AUDIT [' + @auditName + '] WITH (STATE = OFF);';
        EXEC sp_executesql @sql;
        
        -- Drop the server audit
        SET @sql = 'DROP SERVER AUDIT [' + @auditName + '];';
        EXEC sp_executesql @sql;
        PRINT 'Dropped server audit: ' + @auditName;
    END

    FETCH NEXT FROM audit_cursor INTO @auditName;
END

CLOSE audit_cursor;
DEALLOCATE audit_cursor;
