function Get-WindowEvent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [datetime]
        $StartTime,

        [datetime]
        $EndTime = $StartTime.AddMinutes(2),

        [switch]
        $unattended,

        $exportPath = "$env:USERPROFILE"
    )

    begin {
        $currentVersion = '1.0.0521.4'
    }

    process {

        #----# Check for admin privileges
        $myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $myWindowsPrincipal = [System.Security.Principal.WindowsPrincipal]::new($myWindowsID)
        $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

        if ((!($myWindowsPrincipal.IsInRole($adminRole))) -and (!$unattended)) {
            [void](Read-Host "`n$(Get-Date) #----# WARNING: You are not presently in admin context, some logs won't be gathered. `nPress Enter to continue or Ctrl + C to abort")
        }

        $listLog = (Get-WinEvent -ListLog * -ErrorAction SilentlyContinue).LogName

        $targetEvents = @()

        foreach($logName in $listLog) {
            "Reading $logName events..."
            $winEventArgs =
            @{
                LogName="$logName"
                StartTime=$StartTime
                EndTime=$EndTime
            }

            try {
                $logEvents = Get-WinEvent -FilterHashtable $winEventArgs -ErrorAction Stop
                $targetEvents += $logEvents
            }
            catch [Exception] {
                if($_.Exception.Message -match "Attempted to perform unauthorized operation") {
                    Write-Host "$(Get-Date) #----# WARNING: Unable to read Event Log `"$logName`"; Access denied;" -ForegroundColor Yellow
                }
                elseif($_.Exception.Message -match "No events were found that match the specified selection criteria") {
                    Write-Verbose "$(Get-Date) #----# INFORMATION: No matching event found in Log $logName;"
                }
                else {
                    Write-Host "$(Get-Date) #----# ERROR: $($_.Exception.Message);" -ForegroundColor Red
                }
            }
            Remove-Variable logEvents,winEventArgs -ErrorAction Ignore
        }

        if($targetEvents) {
            $messages = $targetEvents.Message | ?{"" -ne $_} | %{$_.Split("`n")[0]} | Select-Object -Unique | Sort-Object
            
            if ($messages) {
                "The following unique events occured:`n$($messages | Out-String)"
                $messages | Out-File "$exportPath\$env:COMPUTERNAME-$($StartTime.ToFileTime())-EventMessages.txt" -Force
            }

            $targetEvents | Export-Csv "$exportPath\$env:COMPUTERNAME-$($StartTime.ToFileTime())-EventData.csv" -NoTypeInformation -Force
        }
        else {
            "No events found;"
        }
    }

    end {

    }

}
