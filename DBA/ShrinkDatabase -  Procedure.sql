CREATE PROCEDURE [ShrinkDatabase] @dbname VARCHAR(128) , @targetpercentfree float
AS
    CREATE TABLE #dbresults
    (dbname VARCHAR(128) ,
    Filename VARCHAR(128),
    type_desc VARCHAR(32),
    CurrentSizeMB FLOAT,
    FreeSpaceMB FLOAT,
    percentagefree FLOAT)

DECLARE @statement NVARCHAR(MAX) 

SET @STATEMENT = '
use ' + @dbname + ' ;
INSERT into #dbresults

SELECT DB_NAME() AS DbName, 
    name AS FileName, 
    type_desc,
    size/128.0 AS CurrentSizeMB,  
    size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0 AS FreeSpaceMB,
    0 as percentageFree
FROM sys.database_files
WHERE type IN (0,1)
AND name not LIKE ''%log%'' '

EXECUTE sp_executesql @statement 
IF @@ERROR > 0
BEGIN 
    PRINT @statement
END

UPDATE #dbresults
SET percentageFree = FreeSpaceMB /(FreeSpaceMB + CurrentSizeMB) * 100

DECLARE @filename NVARCHAR(128), @currentsize INT, @targetsize FLOAT, @percentagefree FLOAT, @freespaceMB float

SELECT @filename = [filename],
@currentsize = CurrentSizeMB,
@freespaceMB = freespaceMB,
@percentagefree = percentagefree
FROM #dbresults

SELECT * FROM #dbresults

SET @targetsize = (@currentsize - @freespaceMB) * (1 + @targetpercentfree  /100)
select @targetsize as TargetSize
-- target percentage should be 10% free if > 12 then shrink
IF @percentagefree > @targetpercentfree
BEGIN
    WHILE 1= 1
        BEGIN
            -- doing this in 1 gb chunks means that it is much likelier to finish 
            SET @currentsize = @currentsize -1000
        
            BEGIN
                IF @currentsize < @targetsize
                BEGIN
                    BREAK
                END

                SET @STATEMENT = ' USE ' + @DBNAME + '; DBCC SHRINKFILE ( ' + + '''' + @filename + '''' + ',' +  convert(varchar,@currentsize) + ' )'
                EXEC sp_executesql @statement 
                IF @@ERROR > 0
                BEGIN 
                    print @statement
                END
            END
        END
END

go 
EXECUTE [ShrinkDatabase] @dbname  = 'databasename', @targetpercentfree = 10