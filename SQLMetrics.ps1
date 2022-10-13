Import-Module AWSPowerShell

$metricName = 'Tempdb Space Used'
$sqlMetric = 'DataSpaceUsed%'
$unit = 'percent'
$namespace = 'dba/SQLServer'

$script = "
USE [tempdb]
select
[DataSpaceUsed%] = ((sum(convert(numeric(10,2),round(fileproperty( a.name,'SpaceUsed')/128.,2)))) / (sum(convert(numeric(10,2),round(a.size/128.,2))))) * 100 
from sysfiles a
where a.[groupid] = 1
"

#Use an AWS Service to get this systems Instance ID
$instanceId = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id")

# Associate current EC2 instance with your custom cloudwatch metric
$instanceDimension = New-Object -TypeName Amazon.CloudWatch.Model.Dimension;
$instanceDimension.Name = "InstanceId";
$instanceDimension.Value = $instanceId;

$instanceDimension2 = New-Object -TypeName Amazon.CloudWatch.Model.Dimension;
$instanceDimension2.Name = "objectname";
$instanceDimension2.Value = "SQLServer:Custom Metrics";

$value = Invoke-Sqlcmd -Query $script | Select-Object -ExpandProperty $sqlMetric

$dimensions = @();
$dimensions += $instanceDimension;
$dimensions += $instanceDimension2;

$metrics = @();
$metric = New-Object -TypeName Amazon.CloudWatch.Model.MetricDatum;
$metric.Timestamp = [DateTime]::UtcNow;
$metric.MetricName = $metricName;
$metric.Value = $value;
$metric.Dimensions = $dimensions;
$metric.unit = $unit
$metrics += $metric;    

try {
    Write-CWMetricData -Namespace $Namespace -MetricData $metrics -Verbose
}
catch {
    Write-Output "CWMetric Failed"
}

#Workers Created
$metricName = 'Workers Created'
$sqlMetric = 'WorkersCreatedPercentage'
$unit = 'percent'
$namespace = 'dba/SQLServer'

$script = "
USE [master]
DECLARE @max DECIMAL(8,2)
DECLARE @current DECIMAL(8,2)
SELECT @max = max_workers_count FROM sys.dm_os_sys_info;
SELECT @current = count (*) FROM sys.dm_os_workers
SELECT CAST(@current / @max * 100 AS INT) AS [WorkersCreatedPercentage]
"

#Use an AWS Service to get this systems Instance ID
$instanceId = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id")

# Associate current EC2 instance with your custom cloudwatch metric
$instanceDimension = New-Object -TypeName Amazon.CloudWatch.Model.Dimension;
$instanceDimension.Name = "InstanceId";
$instanceDimension.Value = $instanceId;

$instanceDimension2 = New-Object -TypeName Amazon.CloudWatch.Model.Dimension;
$instanceDimension2.Name = "objectname";
$instanceDimension2.Value = "SQLServer:Custom Metrics";

$value = Invoke-Sqlcmd -Query $script | Select-Object -ExpandProperty $sqlMetric

$dimensions = @();
$dimensions += $instanceDimension;
$dimensions += $instanceDimension2;

$metrics = @();
$metric = New-Object -TypeName Amazon.CloudWatch.Model.MetricDatum;
$metric.Timestamp = [DateTime]::UtcNow;
$metric.MetricName = $metricName;
$metric.Value = $value;
$metric.Dimensions = $dimensions;
$metric.unit = $unit
$metrics += $metric;    

try {
    Write-CWMetricData -Namespace $Namespace -MetricData $metrics -Verbose
}
catch {
    Write-Output "CWMetric Failed"
}


# Waiting Tasks
$metricName = 'Waiting Tasks'
$sqlMetric = 'WaitingTasks'
$unit = 'count'
$namespace = 'dba/SQLServer'

$script = "
USE [master]
select count(*) AS WaitingTasks
FROM sys.dm_os_waiting_tasks owt
INNER JOIN sys.dm_exec_sessions es ON owt.session_id = es.session_id
where es.is_user_process = 1
AND wait_duration_ms > 1000
and (owt.wait_type <> 'WAITFOR' or es.login_name not like '%sql_agent%')
"

#Use an AWS Service to get this systems Instance ID
$instanceId = (New-Object System.Net.WebClient).DownloadString("http://169.254.169.254/latest/meta-data/instance-id")

# Associate current EC2 instance with your custom cloudwatch metric
$instanceDimension = New-Object -TypeName Amazon.CloudWatch.Model.Dimension;
$instanceDimension.Name = "InstanceId";
$instanceDimension.Value = $instanceId;

$instanceDimension2 = New-Object -TypeName Amazon.CloudWatch.Model.Dimension;
$instanceDimension2.Name = "objectname";
$instanceDimension2.Value = "SQLServer:Custom Metrics";

$value = Invoke-Sqlcmd -Query $script | Select-Object -ExpandProperty $sqlMetric

$dimensions = @();
$dimensions += $instanceDimension;
$dimensions += $instanceDimension2;

$metrics = @();
$metric = New-Object -TypeName Amazon.CloudWatch.Model.MetricDatum;
$metric.Timestamp = [DateTime]::UtcNow;
$metric.MetricName = $metricName;
$metric.Value = $value;
$metric.Dimensions = $dimensions;
$metric.unit = $unit
$metrics += $metric;    

try {
    Write-CWMetricData -Namespace $Namespace -MetricData $metrics -Verbose
}
catch {
    Write-Output "CWMetric Failed"
}