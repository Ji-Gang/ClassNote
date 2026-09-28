# Storage.ps1 — dot-sourced in Desktop.ps1 initialization order.
function Save-Data {
 $json=$script:db|ConvertTo-Json -Depth 15
 if($script:lastSavedJson -ceq $json){return}
 $temp="$script:path.tmp"; [IO.File]::WriteAllText($temp,$json,(New-Object Text.UTF8Encoding($false)))
 [IO.File]::Replace($temp,$script:path,(Join-Path $script:appRoot 'data.backup.json'))
 $script:lastSavedJson=$json
}
function Key($s) { if($s.key){return $s.key}; if($s.sourceId){return $s.sourceId}; "$($s.date)|$($s.course)|$($s.start)|$($s.end)" }
function Record($s) {
 $key=Key $s; $r=@($script:db.records|Where-Object {$_.key -eq $key})|Select-Object -First 1
 if (-not $r) { $r=[pscustomobject]@{key=$key;course=$s.course;date=$s.date;start=$s.start;end=$s.end;notes='';tasks=@();saved=$false;snooze=''}; $script:db.records=@($script:db.records)+$r }
 return $r
}
function Capture-Draft {
 if (-not $script:active -or $script:loading) { return }
 $script:active.notes=$notes.Text; $old=@($script:active.tasks)
 $script:active.tasks=@($tasks.Lines|Where-Object {$_.Trim()}|ForEach-Object {
   $t=$_.Trim(); [pscustomobject]@{text=$t;done=(@($old|Where-Object {$_.text -eq $t -and $_.done}).Count -gt 0)}
 }); Save-Data
}
