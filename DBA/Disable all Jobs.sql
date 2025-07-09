USE msdb;
GO

DECLARE @job_id UNIQUEIDENTIFIER;
DECLARE @job_name NVARCHAR(128);
DECLARE @command NVARCHAR(MAX);

-- Cursor to loop through all jobs
DECLARE job_cursor CURSOR FOR
SELECT job_id, name
FROM dbo.sysjobs;

OPEN job_cursor;
FETCH NEXT FROM job_cursor INTO @job_id, @job_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Disable the job
    EXEC msdb.dbo.sp_update_job 
        @job_id = @job_id, 
        @enabled = 0;
    
    PRINT 'Disabled job: ' + @job_name;
    
    FETCH NEXT FROM job_cursor INTO @job_id, @job_name;
END;

CLOSE job_cursor;
DEALLOCATE job_cursor;
GO
