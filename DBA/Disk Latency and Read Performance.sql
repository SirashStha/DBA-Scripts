SELECT 
    database_id, 
    file_id, 
    io_stall_read_ms, 
    num_of_reads,
    io_stall_read_ms / NULLIF(num_of_reads, 0) AS avg_read_latency_ms
FROM sys.dm_io_virtual_file_stats(NULL, NULL)
ORDER BY avg_read_latency_ms DESC;
