
/*
This script is used to shrink a database file in
increments until it reaches a target free space limit.
Run this script in the database with the file to be shrunk.
1. Set @DBFileName to the name of database file to shrink.
2. Set @TargetFreeMB to the desired file free space in MB after shrink.
3. Set @ShrinkIncrementMB to the increment to shrink file by in MB
4. Run the script
Comments	:	- This script will help shrink database in chunks.
                        - Remember : Shriking a database file should be done as a last practice.
                        - http://www.sqlskills.com/blogs/paul/why-you-should-not-shrink-your-data-files/
                        - https://www.brentozar.com/archive/2009/08/stop-shrinking-your-database-files-seriously-now/
*/                      
declare @DBFileName sysname
declare @TargetFreeMB int
declare @ShrinkIncrementMB int

-- Set Name of Database file to shrink
set @DBFileName = 'GLTRAN_DATA'  --<--- CHANGE HERE !!

-- Set Desired file free space in MB after shrink
set @TargetFreeMB = 1000			--<--- CHANGE HERE !!

-- Set Increment to shrink file by in MB
set @ShrinkIncrementMB = 500			--<--- CHANGE HERE !!

-- Show Size, Space Used, Unused Space, and Name of all database files
select
        [FileSizeMB]    =
                convert(numeric(10,2),round(a.size/128.,2)),
        [UsedSpaceMB]   =
                convert(numeric(10,2),round(fileproperty( a.name,'SpaceUsed')/128.,2)) ,
        [UnusedSpaceMB] =
                convert(numeric(10,2),round((a.size-fileproperty( a.name,'SpaceUsed'))/128.,2)) ,
        [DBFileName]    = a.name
from
        sysfiles a

declare @sql varchar(8000)
declare @SizeMB int
declare @UsedMB int

-- Get current file size in MB
select @SizeMB = size/128. from sysfiles where name = @DBFileName

-- Get current space used in MB
select @UsedMB = fileproperty( @DBFileName,'SpaceUsed')/128.

select [StartFileSize] = @SizeMB, [StartUsedSpace] = @UsedMB, [DBFileName] = @DBFileName

-- Loop until file at desired size
while  @SizeMB > @UsedMB+@TargetFreeMB+@ShrinkIncrementMB
        begin

        set @sql =
        'dbcc shrinkfile ( '+@DBFileName+', '+
        convert(varchar(20),@SizeMB-@ShrinkIncrementMB)+' ) '

        print 'Start ' + @sql
        print 'at '+convert(varchar(30),getdate(),121)

        exec ( @sql )

        print 'Done ' + @sql
        print 'at '+convert(varchar(30),getdate(),121)

        -- Get current file size in MB
        select @SizeMB = size/128. from sysfiles where name = @DBFileName
        
        -- Get current space used in MB
        select @UsedMB = fileproperty( @DBFileName,'SpaceUsed')/128.

        select [FileSize] = @SizeMB, [UsedSpace] = @UsedMB, [DBFileName] = @DBFileName

        end

select [EndFileSize] = @SizeMB, [EndUsedSpace] = @UsedMB, [DBFileName] = @DBFileName

-- Show Size, Space Used, Unused Space, and Name of all database files
select
        [FileSizeMB]    =
                convert(numeric(10,2),round(a.size/128.,2)),
        [UsedSpaceMB]   =
                convert(numeric(10,2),round(fileproperty( a.name,'SpaceUsed')/128.,2)) ,
        [UnusedSpaceMB] =
                convert(numeric(10,2),round((a.size-fileproperty( a.name,'SpaceUsed'))/128.,2)) ,
        [DBFileName]    = a.name
from
        sysfiles a

GO

DBCC CHECKdb('INFINITY_020_001') WITH NO_INFOMSGS
GO
