# Bootstrap.ps1 — dot-sourced in Desktop.ps1 initialization order.
$mutex=New-Object Threading.Mutex($false,'Local\ClassNoteDesktopFramework')
$signal=Join-Path $script:appRoot 'show-window.signal'
if (-not $mutex.WaitOne(0)) { [IO.File]::WriteAllText($signal,'show'); exit }
$script:path=Join-Path $script:appRoot 'data.json'
if (-not (Test-Path $script:path)) {
 $rows=@(Import-Csv (Join-Path $script:appRoot 'schedule-example.csv') -Encoding UTF8)
 foreach($row in $rows){$row.date=Get-Date -Format 'yyyy-MM-dd'}
 [IO.File]::WriteAllText($script:path,([pscustomobject]@{demo=$true;schedule=$rows;records=@()}|ConvertTo-Json -Depth 8),(New-Object Text.UTF8Encoding($false)))
}
$script:db=Get-Content $script:path -Raw -Encoding UTF8 | ConvertFrom-Json
if(-not $script:db.PSObject.Properties['pinned']){$script:db|Add-Member -NotePropertyName pinned -NotePropertyValue $true}
$script:active=$null; $script:loading=$false; $script:quitting=$false
$script:course=''; $script:announced=@{}; $script:toasts=@(); $script:todoWindow=$null
