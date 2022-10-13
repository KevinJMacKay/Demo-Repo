param(
    [parameter()][string]$Server,
    [parameter()][string]$CloudWatchAlarm,
    [parameter()][string]$DriveLetter	
)

if (Test-Path C:\Modules\SQL_Admin.psm1) {
    Import-Module C:\Modules\SQL_Admin.psm1
}
elseif (Test-Path $PSScriptRoot\..\..\Modules\SQL_Admin.psm1) {
    Import-Module $PSScriptRoot\..\..\Modules\SQL_Admin.psm1
}
else {
    exit
}

$sqlinfoJson = Get-sqlinfo
$instance = Get-ec2instance -Filter @{name = 'tag:Name'; values = "$Server" }
$InstanceId = $Instance.Instances.InstanceId
$Environment = Get-Environment
$arn = $sqlinfoJson.datacenters.aws.$Environment.ARN
$Namespace = $sqlinfoJson.datacenters.aws.Alarms.$CloudWatchAlarm.Namespace
$Threshold = $sqlinfoJson.datacenters.aws.Alarms.$CloudWatchAlarm.Threshold
$ComparisonOperator = $sqlinfoJson.datacenters.aws.Alarms.$CloudWatchAlarm.ComparisonOperator
$Statistic = $sqlinfoJson.datacenters.aws.Alarms.$CloudWatchAlarm.Statistic
$Period = $sqlinfoJson.datacenters.aws.Alarms.$CloudWatchAlarm.Period
$Unit = $sqlinfoJson.datacenters.aws.Alarms.$CloudWatchAlarm.Unit
$EvaluationPeriods = $sqlinfoJson.datacenters.aws.Alarms.$CloudWatchAlarm.EvaluationPeriods
$TreatMissingData = $sqlinfoJson.datacenters.aws.Alarms.$CloudWatchAlarm.TreatMissingData
$Expression = $sqlinfoJson.datacenters.aws.Alarms.$CloudWatchAlarm.Expression
$AWSAlarmTags = $sqlinfojson.datacenters.aws.AWSAlarmTags

if ($DriveLetter) {
    $DriveLetter = $DriveLetter + ":"
    $Metric1 = Get-CWMetricList -Namespace $Namespace | Where-Object { $_.MetricName -eq "Megabytes Free" -AND $_.dimensions.value -eq $InstanceId -AND $_.dimensions.value -eq $DriveLetter }
    $Metric2 = Get-CWMetricList -Namespace $Namespace | Where-Object { $_.MetricName -eq "Percent Free" -AND $_.dimensions.value -eq $InstanceId -AND $_.dimensions.value -eq $DriveLetter }
    #wait for metrics to be available in cloudwatch
    Write-host "Waiting for metrics to become available..."
    while ($null -eq $Metric1) {
        start-sleep 10
        $count = $count + 1
        $Metric1 = Get-CWMetricList -Namespace $Namespace | Where-Object { $_.MetricName -eq "Megabytes Free" -AND $_.dimensions.value -eq $InstanceId -AND $_.dimensions.value -eq $DriveLetter }
        while ($count -eq 3) {
            Write-host "Waiting 30 sec for metrics to become available"
            $count = 0
        }
    }
    while ($null -eq $Metric2) {
        start-sleep 10
        $count = $count + 1
        $Metric2 = Get-CWMetricList -Namespace $Namespace | Where-Object { $_.MetricName -eq "Percent Free" -AND $_.dimensions.value -eq $InstanceId -AND $_.dimensions.value -eq $DriveLetter }
        while ($count -eq 3) {
            Write-host "Waiting 30 sec for metrics to become available"
            $count = 0
        }
    }
    $AlarmName = "$Environment - $Server - Monitor - $CloudWatchAlarm - $DriveLetter"
    Write-Host "Attempting to create $AlarmName"
    #Expression1
    $Expression1 = New-Object Amazon.CloudWatch.Model.MetricDataQuery
    $Expression1.Expression = $Expression
    $Expression1.id = "e1"
    $Expression1.label = "Expression1"
    $Expression1.ReturnData = $TRUE
    #Metric1 - Megabytes Free
    $Metric1 = New-Object Amazon.CloudWatch.Model.MetricDataQuery
    $MetricStat1 = New-Object Amazon.CloudWatch.Model.MetricStat
    $MetricStat1.metric = Get-CWMetricList -Namespace $Namespace | Where-Object { $_.MetricName -eq "Megabytes Free" -AND $_.dimensions.value -eq $InstanceId -AND $_.dimensions.value -eq $DriveLetter }
    $Metric1.MetricStat = $MetricStat1
    $Metric1.id = "m1"
    $Metric1.metricstat.period = $Period
    $Metric1.metricstat.Stat = $Statistic
    $Metric1.ReturnData = $FALSE
    #Metric2 - Percent Free
    $Metric2 = New-Object Amazon.CloudWatch.Model.MetricDataQuery
    $MetricStat2 = New-Object Amazon.CloudWatch.Model.MetricStat
    $MetricStat2.metric = Get-CWMetricList -Namespace $Namespace | Where-Object { $_.MetricName -eq "Percent Free" -AND $_.dimensions.value -eq $InstanceId -AND $_.dimensions.value -eq $DriveLetter }
    $Metric2.MetricStat = $MetricStat2
    $Metric2.id = "m2"
    $Metric2.metricstat.period = $Period
    $Metric2.metricstat.Stat = $Statistic
    $Metric2.ReturnData = $FALSE
    #Target
    $Target = @()
    $Target += $Expression1
    $Target += $Metric1
    $Target += $Metric2

    Write-CWMetricAlarm -AlarmName $AlarmName `
        -Metric $Target `
        -EvaluationPeriods $EvaluationPeriods `
        -Threshold $Threshold `
        -ActionsEnabled $true `
        -AlarmAction $arn `
        -OKAction $arn `
        -ComparisonOperator $ComparisonOperator
    $Verify = Get-CWAlarm -AlarmName $AlarmName
    if ($Verify) {
        Write-Host "Alarm ($AlarmName) created successfully`n" 
        $AlarmArn = $Verify.AlarmARN
        foreach ($AWSAlarmTag in $AWSAlarmTags) { 
            $Key = $AWSAlarmTag.Key
            $Value = $AWSAlarmTag.Value
            Write-host "  Tag Creation $Key - $Value"
            Add-CWResourceTag -ResourceARN $AlarmARN -Tag $AWSAlarmTag
        }  
    }
    else {
        Write-Error "Alarm ($AlarmName) creation failed`n" 
    }
}
else {
    #wait for metrics to be available in cloudwatch
    $Metric = Get-CWMetricList -Namespace $Namespace | Where-Object { $_.MetricName -eq "$CloudWatchAlarm" -AND $_.Dimensions.value -eq $InstanceId }
    while ($null -eq $Metric) {
        Write-host "Waiting for metrics to become available..."
        start-sleep 10
        $count = $count + 1
        $Metric = Get-CWMetricList -Namespace $Namespace | Where-Object { $_.MetricName -eq "$CloudWatchAlarm" -AND $_.Dimensions.value -eq $InstanceId }
        while ($count -eq 3) {
            Write-host "Waiting 30 sec..."
            $count = 0
        }
    }
    $AlarmName = "$Environment - $Server - Monitor - $($Metric.MetricName)"
    Write-Host "Attempting to create $AlarmName"

    Write-CWMetricAlarm -AlarmName $AlarmName `
        -AlarmDescription "$AlarmName - $ComparisonOperator - $Threshold" `
        -MetricName $Metric.MetricName `
        -Namespace $Namespace `
        -Statistic $Statistic `
        -Period $Period `
        -Unit $Unit `
        -EvaluationPeriods $EvaluationPeriods `
        -Threshold $Threshold `
        -ActionsEnabled $true `
        -AlarmAction $arn `
        -OKAction $arn `
        -TreatMissingData $TreatMissingData `
        -ComparisonOperator $ComparisonOperator `
        -Dimension $Metric.Dimensions
    $Verify = Get-CWAlarm -AlarmName $AlarmName
    if ($Verify) {
        Write-Host "Alarm ($AlarmName) created successfully`n" 
        $AlarmArn = $Verify.AlarmARN
        foreach ($AWSAlarmTag in $AWSAlarmTags) { 
            $Key = $AWSAlarmTag.Key
            $Value = $AWSAlarmTag.Value
            Write-host "  Tag Creation $Key - $Value"
            Add-CWResourceTag -ResourceARN $AlarmARN -Tag $AWSAlarmTag
        }  
    }
    else {
        Write-Error "Alarm ($AlarmName) creation failed`n" 
    }
}	