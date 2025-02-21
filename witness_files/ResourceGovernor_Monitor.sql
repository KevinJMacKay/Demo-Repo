--SELECT name, max_iops_per_volume FROM sys.resource_governor_resource_pools WHERE name = 'MainDataExportPool'

select login_name, program_name, session_id, host_name, login_time from sys.dm_exec_sessions
where nt_user_name = 'gmsa-vu$' 
order by program_name desc
go

select count(*),
	s.nt_user_name,
	g.name as rg_group_name
from sys.dm_exec_sessions s
join sys.dm_resource_governor_workload_groups g
	on s.group_id = g.group_id
where s.nt_user_name = 'gmsa-vu$'
group by s.nt_user_name, g.name 

select 
	s.login_name, 
	s.program_name, 
	s.session_id, 
	s.host_name, 
	s.login_time,
	g.name as rg_group_name
from sys.dm_exec_sessions s
join sys.dm_resource_governor_workload_groups g
	on s.group_id = g.group_id
where s.nt_user_name = 'gmsa-vu$'
order by program_name desc



:connect AP02ARSQLB103

select login_name, program_name, session_id, host_name, login_time from sys.dm_exec_sessions
where nt_user_name = 'gmsa-vu$'
order by program_name desc
go

select 
	s.login_name, 
	s.program_name, 
	s.session_id, 
	s.host_name, 
	s.login_time,
	g.name as rg_group_name
from sys.dm_exec_sessions s
join sys.dm_resource_governor_workload_groups g
	on s.group_id = g.group_id
where s.nt_user_name = 'gmsa-vu$'
/*
login_name	program_name	session_id	host_name	login_time
AAS2\gmsa-vu$	MainDataExport	316	IP-AC1E30D7	2023-11-08 17:43:54.807
*/