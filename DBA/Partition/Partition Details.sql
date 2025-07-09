-- Set your desired filegroup name here
DECLARE @FilegroupName SYSNAME = 'PRIMARY';  -- Change to your filegroup

-- =========================================
-- 1. Filegroup and File Info
-- =========================================
PRINT '=== Filegroup and File Info ===';
SELECT 
    fg.name AS FilegroupName,
    f.name AS FileName,
    f.physical_name,
    f.type_desc,
    f.size * 8 / 1024 AS SizeMB
FROM 
    sys.filegroups fg
JOIN 
    sys.database_files f ON fg.data_space_id = f.data_space_id


-- =========================================
-- 2. Tables Stored in Filegroup
-- =========================================
PRINT '=== Tables in Filegroup ===';
SELECT 
    fg.name AS FilegroupName,
    s.name AS SchemaName,
    t.name AS TableName,
    i.type_desc AS IndexType,
    i.name AS IndexName
FROM 
    sys.tables t
JOIN 
    sys.indexes i ON t.object_id = i.object_id AND i.index_id <= 1  -- heap or clustered
JOIN 
    sys.data_spaces ds ON i.data_space_id = ds.data_space_id
JOIN 
    sys.filegroups fg ON ds.data_space_id = fg.data_space_id
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    fg.name = @FilegroupName AND t.name = 'GLTRAN_DETL'
ORDER BY 
    s.name, t.name;

-- =========================================
-- 3. Indexes Stored in Filegroup
-- =========================================
PRINT '=== Indexes in Filegroup ===';
SELECT 
    fg.name AS FilegroupName,
    s.name AS SchemaName,
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType
FROM 
    sys.indexes i
JOIN 
    sys.tables t ON i.object_id = t.object_id
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
JOIN 
    sys.data_spaces ds ON i.data_space_id = ds.data_space_id
JOIN 
    sys.filegroups fg ON ds.data_space_id = fg.data_space_id
WHERE 
    i.index_id > 0  -- only actual indexes
    AND fg.name = @FilegroupName AND t.name = 'GLTRAN_DETL'
ORDER BY 
    s.name, t.name, i.name;

-- =========================================
-- 4. Partitions and Allocation Units
-- =========================================
PRINT '=== Allocation Units in Filegroup ===';
SELECT 
    fg.name AS FilegroupName,
    s.name AS SchemaName,
    t.name AS TableName,
    au.type_desc AS AllocationType,
    p.rows AS 'ROWCOUNT',
	p.partition_number,
	p.index_id
FROM 
    sys.partitions p
JOIN 
    sys.allocation_units au ON p.partition_id = au.container_id
JOIN 
    sys.data_spaces ds ON au.data_space_id = ds.data_space_id
JOIN 
    sys.filegroups fg ON ds.data_space_id = fg.data_space_id
JOIN 
    sys.tables t ON p.object_id = t.object_id
JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    fg.name = @FilegroupName AND t.name = 'GLTRAN_DETL'
ORDER BY 
    s.name, t.name;
