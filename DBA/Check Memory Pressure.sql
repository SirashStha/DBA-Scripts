SELECT 
    total_physical_memory_kb / 1024 AS TotalMB,
    available_physical_memory_kb / 1024 AS AvailableMB,
    total_page_file_kb / 1024 AS PageFileMB,
    available_page_file_kb / 1024 AS PageFileFreeMB,
    system_memory_state_desc
FROM sys.dm_os_sys_memory;
