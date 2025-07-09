-- Check Fragmentation Columnstore Indexes
SELECT 
    object_name(i.object_id) AS TableName,
    i.name AS IndexName,
    rg.row_group_id,
    rg.state_desc AS RowgroupState,   -- OPEN, COMPRESSED, TOMBSTONE, etc.
    rg.total_rows,
    rg.deleted_rows,
    rg.trim_reason_desc,              -- Reason for trimming rowgroup (deletes, threshold, etc.)
    rg.total_rows - rg.deleted_rows AS ActiveRows,
    rg.deleted_rows * 100.0 / rg.total_rows AS DeletePercentage,
    rg.size_in_bytes / 1024 / 1024 AS SizeMB
FROM 
    sys.dm_db_column_store_row_group_physical_stats rg
JOIN 
    sys.indexes i ON rg.object_id = i.object_id AND rg.index_id = i.index_id
WHERE 
    i.object_id = OBJECT_ID('GLTRAN_DETL')  -- replace with your table name
ORDER BY 
    rg.state_desc, rg.row_group_id;


