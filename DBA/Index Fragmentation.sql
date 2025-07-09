-- Find Index Fragmentation 

SELECT S.name as 'Schema',
T.name as 'Table',
I.name as 'Index',
DDIPS.avg_fragmentation_in_percent,
DDIPS.page_count
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS DDIPS
INNER JOIN sys.tables T on T.object_id = DDIPS.object_id
INNER JOIN sys.schemas S on T.schema_id = S.schema_id
INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id
AND DDIPS.index_id = I.index_id
WHERE DDIPS.database_id = DB_ID()
and I.name is not null
AND DDIPS.avg_fragmentation_in_percent > 0
ORDER BY DDIPS.avg_fragmentation_in_percent DESC

SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    i.name AS IndexName,
    ps.row_group_id,
    ps.state_desc AS RowGroupState,
    ps.total_rows,
    ps.deleted_rows,
    CAST(100.0 * ps.deleted_rows / NULLIF(ps.total_rows, 0) AS DECIMAL(5,2)) AS DeletedRowsPercent,
    'ALTER INDEX [' + i.name + '] ON [' + s.name + '].[' + t.name + '] REBUILD;' AS RebuildCommand
FROM 
    sys.dm_db_column_store_row_group_physical_stats AS ps
JOIN sys.indexes AS i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
JOIN sys.tables AS t ON i.object_id = t.object_id
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE 
    i.type_desc = 'COLUMNSTORE'
    AND ps.deleted_rows > 0
    AND (100.0 * ps.deleted_rows / NULLIF(ps.total_rows, 0)) >= 0
ORDER BY 
    DeletedRowsPercent DESC;