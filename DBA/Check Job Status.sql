SELECT 
    j.name AS JobName,
    s.name AS ScheduleName,
    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS LastRunTime,
    CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        ELSE 'Unknown'
    END AS LastRunStatus,
    msdb.dbo.agent_datetime(sch.next_run_date, sch.next_run_time) AS NextScheduledRunTime
FROM 
    msdb.dbo.sysjobs j
LEFT JOIN 
    msdb.dbo.sysjobhistory h ON j.job_id = h.job_id
LEFT JOIN 
    msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
LEFT JOIN 
    msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
OUTER APPLY
    (SELECT 
         next_run_date, next_run_time
     FROM 
         msdb.dbo.sysjobschedules
     WHERE 
         job_id = j.job_id
    ) sch
WHERE 
    j.enabled = 1  -- Only include enabled jobs
    AND h.instance_id = (
        SELECT MAX(h2.instance_id)
        FROM msdb.dbo.sysjobhistory h2
        WHERE h2.job_id = j.job_id
    )
ORDER BY 
    NextScheduledRunTime, LastRunTime DESC;
