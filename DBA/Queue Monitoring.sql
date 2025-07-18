SELECT ag.name as [Availability Group]
		, ar.replica_server_name as [Server]
		, DB_NAME(drs.database_id) as [Database]
		, case when ars.is_local = 1 then 'Local' else 'Remote' end as [DB Location]
		, ars.role_desc as [Replica Role]
		, drs.synchronization_state_desc as [Sync State]
		, ars.synchronization_health_desc as [Health State]
		, drs.log_send_queue_size as [Send Queue Size (KB)]
		, drs.log_send_rate as [Send Rate KB/Sec]
		, drs.redo_queue_size as [Redo Queue Size(KB)]
		, drs.redo_rate as [Redo Rate KB/Sec]
		, drs.last_commit_time as [Last Commit Time]
FROM
 sys.availability_groups ag with(nolock)
	join sys.availability_replicas ar on ag.group_id = ar.group_id
	join sys.dm_hadr_availability_replica_states ars with(nolock) on ar.replica_id = ars.replica_id
	join sys.dm_hadr_database_replica_states drs with(nolock) on ag.group_id = drs.group_id and ars.replica_id = drs.replica_id
order by [database], drs.database_id, ar.replica_server_name
option(recompile, maxdop 1);

