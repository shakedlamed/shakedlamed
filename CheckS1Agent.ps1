<#
 File: SentinelAgentAlert.ps1
 Created: 09/03/2021
 Author: Kobi Dikrman, kobid@sentinelone.com
 Copyright (c) SentinelONE, 2021
 Project: Check SentinelONE Agent Health Status
#>
function Send-SlackMessage ($Text, $Color, $Icon)
{
  # Send Slack WebHook Message
  $uriSlack = "https://hooks.slack.com/services/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"
  $body = ([PSCustomObject]@{
      icon_emoji  = $Icon
      username    = "SentinelONE Agent Health Alert"
      attachments = @(@{
          title       = ("Computer Name: " + $env:COMPUTERNAME + "`nIP Address: " + $IP_Address + "`nUser Name: " + $env:USERNAME)
          text        = $Text
          color       = $Color
          footer      = "SentinelONE Agent Helath Alert"
          footer_icon = "https://www.netprotocol.net/wp-content/uploads/2018/07/sentinelone-icon-200x200.png"
        })
    } | ConvertTo-Json)
  Invoke-RestMethod -uri $uriSlack -Method Post -body $body -ContentType 'application/json' | Out-Null
}
function Log
{
  param ([string]$Text)
  $Time = (Get-Date).ToString('dd/MM/yyyy HH:mm:ss.fff')
  Out-File $Log_File_Location -Append -NoClobber -InputObject "[$Time] $Text" -Encoding ASCII
}
# Vars
$WMI_Agent = Get-WmiObject win32_product | ? { $_.name -match "Sentinel Agent" }
$IP_Address = ((Get-WmiObject Win32_NetworkAdapterConfiguration | ? { $_.ServiceName -notmatch "VM" } | ? { $_.IPEnabled -eq $true }).IPAddress)[0]
$Processes_Status = Get-Process Sentinel*
$Sentinel_Services = Get-Service sentinel*, LogProcessorService
$VSS_Status = $Services_Status | ? { $_.Name -eq "VSS" }
$Flag_Path = "HKCU:\SOFTWARE\S1Alert"
[int]$S1_Score = "0"

# Set Log file location to network location, if the network location isn't avilable set it to local drive
$Global:log_folder = "\\na\users\public\shakedl\logs\"
if (!(Test-Path $log_folder -ErrorAction SilentlyContinue))
{
  $Global:log_folder = "C:\Windows\Temp\S1Alert\"
  mkdir $log_folder -ErrorAction SilentlyContinue
}
$Global:Log_File_Location = ($log_folder + "S1Alert_" + $env:COMPUTERNAME + "_" + (Get-Date).ToString("ddMMyyHHmm")) + ".txt"

if ($WMI_Agent)
{
  # Get Agent Executable by Service
  $Agent_Path = (Get-WmiObject Win32_Service | ? { $_.name -eq "SentinelAgent" })

  # Get Agent Version
  $Agent_Version = (Get-Item ($Agent_Path.pathname -replace ('"', ''))).VersionInfo.ProductVersion

  # Check Services Status
  if ($Sentinel_Services | ? { $_.Status -notcontains "Running" })
  {
    Start-Sleep -Seconds 45
    $Sentinel_Services.Refresh()
    if ($Sentinel_Services | ? { $_.Status -notcontains "Running" })
    {
      $NR_Services = ($Sentinel_Services | ? { $_.Status -notcontains "Running" }).name -join ", "
      $Global:Body_Alert = "`nSentinel Services are Not Running ( " + $NR_Services + " )"
      $S1_Score = $S1_Score + 1
    }
  }

  # Check Protection Status
  $ctlcmd = ($Agent_Path.pathname).replace("SentinelAgent.exe", "SentinelCtl.exe")
  $sp_status = &($ctlcmd -replace ('"', '')) status  | Select-String "Self-Protection status"
  if ($sp_status -notmatch "On")
  {
    $Global:Body_Alert = $Global:Body_Alert + "`nAgent Protection is Off"
    $S1_Score = $S1_Score + 1
  }

  # Check Volume Shadow Copy Service - service state need to set as Manual
  if ($VSS_Status | ? { $_.StartMode -ne "Manual" })
  {
    $Global:Body_Alert = $Global:Body_Alert + "`nVSS Service Status Error"
    $S1_Score = $S1_Score + 1
  }

  # Monitor if Sentinel Agent Process is Running
  if ($Processes_Status.Name -notcontains "SentinelAgent")
  {
    $Global:Body_Alert = $Global:Body_Alert + "`nSentinel Agent Process isn't Running"
    $S1_Score = $S1_Score + 1
  }

  # Check for crashdump files
  $Crash_Dump = (Get-ChildItem 'C:\Programdata\Sentinel\CrashDumps').count
  if ($Crash_Dump -ne "0")
  {
    $Global:Body_Alert = $Global:Body_Alert + "`nCrash Dump Folder isn't Empty"
    $S1_Score = $S1_Score + 1
  }

  if ($S1_Score -ne "0")
  {
    if (!(Test-Path $Flag_Path))
    {
      # Create Flag - to prevent recurrence
      New-Item $Flag_Path
      # Write the events to log file
      log -Text $Body_Alert
      $Global:Body_Alert = $Global:Body_Alert + "`nLogs Location: " + $Log_File_Location
      # send yellow alert if the agent is installed but the score not equal to 0
      Send-SlackMessage -Text $Body_Alert -Color "#e3db00" -Icon ":large_yellow_circle:"
    }
  }
  if ($S1_Score -eq "0")
  {
    if (Test-Path $Flag_Path)
    {
      # Remove Flag
      Remove-Item $Flag_Path
      # send green alert if the status changed to healthy
      Send-SlackMessage -Text "Agent Health Status is Good" -Color "#04e000" -Icon ":large_green_circle:"
    }
  }
}
else
{
  # send red alert if agent isn't installed
  Send-SlackMessage -Text  "SentinelONE Agent isn't Installed" -Color "#c90000" -Icon ":red_circle:"
}
Start-Sleep -Seconds 5
Start-ScheduledTask -TaskName "Check S1 Agent Status"
