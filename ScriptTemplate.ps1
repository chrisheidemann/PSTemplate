@@ -0,0 +1,96 @@
####Script specific variables here2
$vdswitchname = "dvSwitch"

#VM specific
$isVMwareScript = "TRUE"
$VI_Server = "VCHOSTNAME"

#credentials file location
$credPath = "E:\powershell\scripts\credentials\creds_vmuser.xml"

#adds VMware snap-ins and sets other values if the script is a VMware script
if ($isVMwareScript)
{
    if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null )
    {
        Add-PsSnapin VMware.VimAutomation.Core; $bSnapinAdded = $true
    }

$PowerCLIEnv = @'
& "C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
'@ 
    Invoke-Expression $PowerCLIEnv

    Set-PowerCLIConfiguration -DefaultVIServerMode Multiple -Confirm:$false -DisplayDeprecationWarnings:$false | Out-Null
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
}

#email specific
$emailNotification = $false
$emailFrom = "VMware Utilities <vmalert@netins.com>"
$emailTo = "VMAlert <vmalert@netins.com>"
$emailAttachments = $fileName
$emailBody = "$scriptName ran successfully on " + $todayDate
$emailSMTPSrv = "SMTPSERVER"
$emailSubject = $scriptName + " run"

#Define some common variables
#file save locations for the transcript
$todayDate = Get-Date -Format yyyy-MM-dd
#gets current script name
$scriptName = $MyInvocation.MyCommand.Name
#strips the extension off the script name
$scriptName = [io.fileinfo] $scriptName | % basename
#gets the path of the script
$filepath = Split-Path -parent $PSCommandPath
#creates a directory structure with a new directory the same name as the script, appends "_Archive" and then a folder in there with the script name and then the date
$filepath = $filepath + "\" + $scriptName+ "_Archive" + "\" + $scriptName + "-" + $todayDate
#creates a file name using the above path and the script name + date for the actual file name
$fileName = $filepath + "\" + $scriptName + "_" + $todayDate + ".txt"
#enables the file clean up section
$fileRetention = $true
#how many days you want to retain
$fileRetentionVal = 60

if((Test-Path $filepath) -eq 0)
{
	New-Item -ItemType Directory -Path $filepath
}

Start-Transcript -path $fileName

#connects to vCenter if this is a VMware script
if ($isVMwareScript)
{
    $vcCreds = Import-Clixml -Path $credPath
    Connect-VIServer -Server $VI_Server -Credential $vcCreds

}

######################################################put script body in here

######################################################end script body


if ($isVMwareScript)
{
    Disconnect-VIserver * -Confirm:$false
}

stop-transcript

#send email notification
if ($emailNotification)
{
	Send-MailMessage -from $emailFrom -to $emailTo -Attachments $emailAttachments -Body $emailBody -DeliveryNotificationOption OnFailure -SmtpServer $emailSMTPSrv -Subject $emailSubject
}

#clean up old files
if ($fileRetention)
{
	# Delete files older than the $limit.
	Get-ChildItem -Path $filepath -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $fileRetentionVal } | Remove-Item -Force

	# Delete any empty directories left behind after deleting the old files.
	Get-ChildItem -Path $filepath -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse
}
