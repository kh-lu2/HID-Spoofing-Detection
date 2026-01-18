$now = Get-Date
$bootTime = [Management.ManagementDateTimeConverter]::ToDmtfDateTime($now)

Unregister-Event -SourceIdentifier 'Keyboard6416' -ErrorAction SilentlyContinue
Unregister-Event -SourceIdentifier 'Process4688' -ErrorAction SilentlyContinue
Get-Event | Remove-Event -ErrorAction SilentlyContinue

Write-Host "[+] Monitoring started at: $($now.ToString())" -ForegroundColor Gray
Write-Host "[+] Waiting for NEW HID keyboard insertions..." -ForegroundColor Cyan


Register-WmiEvent -Query "SELECT * FROM __InstanceCreationEvent WITHIN 1 
    WHERE TargetInstance ISA 'Win32_NTLogEvent'
    AND TargetInstance.EventCode = '6416'
    AND TargetInstance.Logfile = 'Security'
    AND TargetInstance.TimeGenerated > '$bootTime'" `
    -SourceIdentifier 'Keyboard6416' | Out-Null


Register-WmiEvent -Query "SELECT * FROM __InstanceCreationEvent WITHIN 1
    WHERE TargetInstance ISA 'Win32_NTLogEvent'
    AND TargetInstance.EventCode = '4688'
    AND TargetInstance.Logfile = 'Security'
    AND TargetInstance.TimeGenerated > '$bootTime'" `
    -SourceIdentifier 'Process4688' | Out-Null


while ($true) {

    $kbdEvent = Wait-Event -SourceIdentifier 'Keyboard6416'
    $kbdObj   = $kbdEvent.SourceEventArgs.NewEvent.TargetInstance
    $strings  = $kbdObj.InsertionStrings

    if ($strings -and ($strings -join ' ') -match 'HID Keyboard Device') {
        $time = (Get-Date).ToString("HH:mm:ss")

        $vid = $null
        $devPid = $null
        foreach ($str in $strings) {
            if ($str -match 'VID_([0-9A-Fa-f]{4})') { $vid = $matches[1] }
            if ($str -match 'PID_([0-9A-Fa-f]{4})') { $devPid = $matches[1] }
        }

        $idMsg = ""
        if ($vid -and $devPid) {
            $idMsg = " (VID: $vid, PID: $devPid)"
        } elseif ($vid) {
            $idMsg = " (VID: $vid)"
        } elseif ($devPid) {
            $idMsg = " (PID: $devPid)"
        }

        Write-Host "`n[!] NEW HID Keyboard detected at $time$idMsg" -ForegroundColor Yellow
        Write-Host "[>] Watching for PowerShell / CMD (10s window)..." -ForegroundColor Green

        $windowEnd = (Get-Date).AddSeconds(10)
        $suspiciousFound = $false

        Get-Event -SourceIdentifier 'Process4688' -ErrorAction SilentlyContinue | Remove-Event

        while ((Get-Date) -lt $windowEnd) {
            $psEvent = Get-Event -SourceIdentifier 'Process4688' -ErrorAction SilentlyContinue | Select-Object -First 1

            if ($psEvent) {
                $procObj   = $psEvent.SourceEventArgs.NewEvent.TargetInstance
                $procName  = $procObj.InsertionStrings[5] 
                
                if ($procName -match 'powershell.exe|cmd.exe') {
                    Write-Host "!!! HACKED HACKED HACKED: $procName spawned !!!" -ForegroundColor Red
                    $suspiciousFound = $true
                    break
                }
                Remove-Event -EventIdentifier $psEvent.EventIdentifier -ErrorAction SilentlyContinue
            }
            Start-Sleep -Milliseconds 250
        }

        if (-not $suspiciousFound) {
            Write-Host "[*] Window closed. No suspicious activity detected." -ForegroundColor DarkGray
        }
    }

    Remove-Event -EventIdentifier $kbdEvent.EventIdentifier -ErrorAction SilentlyContinue
}