DECLARE @TableName NVARCHAR(128);
DECLARE @IndexID INT;
DECLARE @IndexName NVARCHAR(128);
DECLARE @SchemaName NVARCHAR(128);
DECLARE @Fragmentation DECIMAL(18,2);
DECLARE @SQL NVARCHAR(MAX);

-- Set the specific table name you want to target
SET @TableName = 'SEQ'; -- Replace 'YourTableName' with the table name
SET @SchemaName = 'dbo'; -- Replace 'dbo' with the schema name if different

-- Temp table to store fragmentation data
IF OBJECT_ID('tempdb..#Fragmentation') IS NOT NULL
    DROP TABLE #Fragmentation;

CREATE TABLE #Fragmentation (
    ObjectID INT,
    IndexID INT,
    Fragmentation DECIMAL(18,2),
    IndexName NVARCHAR(128)
);

-- Get the index fragmentation data
INSERT INTO #Fragmentation (ObjectID, IndexID, Fragmentation, IndexName)
SELECT 
    s.object_id AS ObjectID,
    s.index_id AS IndexID,
    avg_fragmentation_in_percent AS Fragmentation,
    i.name AS IndexName
FROM 
    sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID(@SchemaName + '.' + @TableName), NULL, NULL, 'LIMITED') s
JOIN 
    sys.indexes i ON i.object_id = s.object_id AND i.index_id = s.index_id
WHERE 
    s.index_id > 0; -- Exclude heap indexes

-- Cursor to loop through fragmented indexes
DECLARE cur CURSOR FOR
SELECT 
    @TableName, 
    IndexID, 
    Fragmentation, 
    IndexName
FROM 
    #Fragmentation
WHERE 
    Fragmentation > 5; -- Only consider indexes with fragmentation above 5%

OPEN cur;

FETCH NEXT FROM cur INTO @TableName, @IndexID, @Fragmentation, @IndexName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Determine whether to reorganize or rebuild based on fragmentation
    IF @Fragmentation < 30
    BEGIN
        SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @SchemaName + '].[' + @TableName + '] REORGANIZE;';
        PRINT 'Reorganizing Index: ' + @IndexName + ' on Table: ' + @TableName + ' Fragmentation: ' + CAST(@Fragmentation AS VARCHAR(10));
    END
    ELSE
    BEGIN
        SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @SchemaName + '].[' + @TableName + '] REBUILD;';
        PRINT 'Rebuilding Index: ' + @IndexName + ' on Table: ' + @TableName + ' Fragmentation: ' + CAST(@Fragmentation AS VARCHAR(10));
    END

    EXEC sp_executesql @SQL;

    FETCH NEXT FROM cur INTO @TableName, @IndexID, @Fragmentation, @IndexName;
END

CLOSE cur;
DEALLOCATE cur;

-- Drop temp table
DROP TABLE #Fragmentation;
