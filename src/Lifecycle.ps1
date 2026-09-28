# Lifecycle.ps1 — dot-sourced in Desktop.ps1 initialization order.
$timer=New-Object Windows.Forms.Timer; $timer.Interval=1000; $script:ticks=0; $script:day=Get-Date -Format 'yyyy-MM-dd'
$timer.Add_Tick({try{
 $script:ticks++; if($script:ticks%5 -eq 0){Capture-Draft}
 if(Test-Path $signal){Remove-Item -LiteralPath $signal; $form.Show(); $form.Activate()}
 if((Get-Date -Format 'yyyy-MM-dd') -ne $script:day){$script:day=Get-Date -Format 'yyyy-MM-dd'; Refresh-Courses}
 # One visible reminder at a time; subsequent reminders stay queued.
 if(@($script:toasts|Where-Object {-not $_.IsDisposed}).Count -gt 0){return}
 foreach($r in @(Get-DueRecords (Get-Date))){
  $token=$r.key+'|'+$r.snooze
  if(-not $script:announced.ContainsKey($token)){$script:announced[$token]=$true; Notify-Record $r; break}
 }
}catch{$status.Text='保存或提醒失败：'+$_.Exception.Message}})
$side.Add_FormClosing({param($sender,$e)Capture-Draft; if(-not $script:quitting){$e.Cancel=$true; $side.Hide()}})
$form.Add_FormClosing({param($sender,$e)Capture-Draft; if(-not $script:quitting){$e.Cancel=$true; $side.Hide(); $form.Hide()}})
. (Join-Path $script:appRoot 'Timetable.ps1')
Update-LocalTimetable
Refresh-Courses; $timer.Start()
try {
 [Windows.Forms.Application]::Run($form)
} finally {
 foreach($clock in @($timer,$animation,$savedToastTimer)){
  $clock.Stop()
  $clock.Dispose()
 }
 $tray.Visible=$false
 $tray.Dispose()
 $mutex.ReleaseMutex()
 $mutex.Dispose()
}
