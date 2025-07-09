/* ========= CONFIGURATION ========= */
DECLARE @FillFactorPercent  INT   = 90;     -- desired FILLFACTOR (90 = 10 % free)
DECLARE @FreeSpace_MainDB_MB FLOAT;
DECLARE @FreeSpace_TempDB_MB FLOAT;
/* ================================= */

/* ---- free space in CURRENT database (data files only) ---- */
SELECT @FreeSpace_MainDB_MB =
       SUM( (size - FILEPROPERTY(name,'SpaceUsed')) * 8.0 / 1024.0 )
FROM   sys.database_files
WHERE  type_desc = 'ROWS';   -- exclude log files

/* ---- free space in tempdb (data files only) --------------- */
EXEC tempdb.sys.sp_executesql
    N'SELECT @FS = SUM( (size - FILEPROPERTY(name,''SpaceUsed'')) * 8.0 / 1024.0 )
        FROM sys.database_files
        WHERE type_desc = ''ROWS'';',
    N'@FS FLOAT OUTPUT',
    @FS = @FreeSpace_TempDB_MB OUTPUT;

/* ----------------------------------------------------------- */

SELECT @FreeSpace_MainDB_MB FreeSpace_MainDB_MB, @FreeSpace_TempDB_MB FreeSpace_TempDB_MB

;WITH IndexSpace AS (
    SELECT
        sch.name  AS SchemaName,
        tbl.name  AS TableName,
        idx.name  AS IndexName,
        idx.type_desc AS IndexType,
        idx.index_id,
        SUM(au.used_pages) * 8.0 / 1024        AS Used_MB,
        SUM(au.total_pages) * 8.0 / 1024       AS Reserved_MB
    FROM
        sys.indexes          AS idx
        JOIN sys.partitions       AS p  ON p.object_id = idx.object_id
                                         AND p.index_id  = idx.index_id
        JOIN sys.allocation_units AS au ON au.container_id = p.partition_id
        JOIN sys.tables           AS tbl ON tbl.object_id = idx.object_id
        JOIN sys.schemas          AS sch ON sch.schema_id = tbl.schema_id
    WHERE
        idx.name IS NOT NULL
        AND idx.is_disabled = 0
        AND p.rows > 0
    GROUP BY
        sch.name, tbl.name, idx.name, idx.type_desc, idx.index_id
)
SELECT
    SchemaName,
    TableName,
    IndexName,
    IndexType,
    Used_MB,
    Reserved_MB,
    ROUND(Used_MB / (@FillFactorPercent / 100.0), 2)                            AS Estimated_Rebuild_Size_MB,
    ROUND((Used_MB / (@FillFactorPercent / 100.0)) - Used_MB, 2)                AS Extra_MB_Needed_MainDB,
    ROUND(Used_MB, 2)                                                           AS TempDB_Required_MB_If_SORT_ON,
    ROUND(Used_MB, 2)                                                           AS MainDB_Extra_MB_If_SORT_OFF,
    CASE
        WHEN ((Used_MB / (@FillFactorPercent / 100.0)) - Used_MB) > @FreeSpace_MainDB_MB
             THEN 'Not enough space in MAIN DB'
        ELSE 'OK'
    END  AS MainDB_Space_Status,
    CASE
        WHEN Used_MB > @FreeSpace_TempDB_MB
             THEN 'Not enough TEMPDB space (SORT_IN_TEMPDB = ON)'
        ELSE 'OK'
    END  AS TempDB_Space_Status
FROM
    IndexSpace
ORDER BY
    Estimated_Rebuild_Size_MB DESC;
