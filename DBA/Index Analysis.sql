DECLARE @ObjectID int
SELECT @ObjectID = OBJECT_ID('web.KeywordRankings')

;WITH preIndexAnalysis
AS (
SELECT
OBJECT_SCHEMA_NAME(t.object_id) as schema_name
,t.name as table_name
,COALESCE(i.name, 'N/A') as index_name
,CASE WHEN i.is_unique = 1 THEN 'UNIQUE ' ELSE '' END + i.type_desc as type_desc
,NULL as impact
,ROW_NUMBER()
OVER (PARTITION BY i.object_id ORDER BY i.is_primary_key desc, ius.user_seeks + ius.user_scans + ius.user_lookups desc) as ranking
,ius.user_seeks + ius.user_scans + ius.user_lookups as user_total
,COALESCE(CAST(100 * (ius.user_seeks + ius.user_scans + ius.user_lookups)
/(NULLIF(SUM(ius.user_seeks + ius.user_scans + ius.user_lookups)
OVER(PARTITION BY i.object_id), 0) * 1.) as decimal(6,2)),0) as user_total_pct
,ius.user_seeks
,ius.user_scans
,ius.user_lookups
,STUFF((SELECT ', ' + c.name
FROM sys.index_columns ic
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = ic.object_id
AND i.index_id = ic.index_id
AND is_included_column = 0
ORDER BY index_column_id ASC
FOR XML PATH('')), 1, 2, '') as indexed_columns
,STUFF((SELECT ', ' + c.name
FROM sys.index_columns ic
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = ic.object_id
AND i.index_id = ic.index_id
AND is_included_column = 1
ORDER BY index_column_id ASC
FOR XML PATH('')), 1, 2, '') as included_columns
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
LEFT OUTER JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND ius.database_id = db_id()
WHERE t.object_id = @ObjectID OR @ObjectID IS NULL
UNION ALL
SELECT
OBJECT_SCHEMA_NAME(mid.object_id) as schema_name
,OBJECT_NAME(mid.object_id) as table_name
,'--MISSING--'
,'--NONCLUSTERED--'
,(migs.user_seeks + migs.user_scans) * migs.avg_user_impact as impact
,0 as ranking
,migs.user_seeks + migs.user_scans as user_total
,NULL as user_total_pct
,migs.user_seeks
,migs.user_scans
,0 as user_lookups
,COALESCE(equality_columns + ', ', SPACE(0)) + COALESCE(inequality_columns, SPACE(0)) as indexed_columns
,included_columns
FROM sys.dm_db_missing_index_details mid
INNER JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats migs ON mig.index_group_handle = migs.group_handle
WHERE database_id = db_id()
AND mid.object_id = @ObjectID OR @ObjectID IS NULL
)
SELECT schema_name
,table_name
,index_name
,type_desc
,impact
,user_total
,user_total_pct
,CAST(100 * (user_seeks + user_scans + user_lookups)
/(NULLIF(SUM(user_seeks + user_scans + user_lookups)
OVER(PARTITION BY schema_name, table_name), 0) * 1.) as decimal(6,2)) as estimated_percent
,user_seeks
,user_scans
,user_lookups
,indexed_columns
,included_columns
FROM preIndexAnalysis
ORDER BY schema_name, table_name, ROW_NUMBER() OVER (PARTITION BY schema_name, table_name ORDER BY user_total desc, ranking)

