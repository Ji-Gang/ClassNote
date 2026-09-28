# Reminders.ps1 — dot-sourced in Desktop.ps1 initialization order.
function Get-DueRecords([datetime]$now){
 $result=@()
 # Explicit snoozes take priority over saved/demo status, including previous dates.
 foreach($r in $script:db.records){if($r.snooze -and [datetime]::Parse($r.snooze) -le $now){$result+=$r}}
 if(-not $script:db.demo){foreach($s in @($script:db.schedule|Where-Object {$_.date -eq $now.ToString('yyyy-MM-dd')})){
  if(-not $s.start -or -not $s.end){continue}
  $end=[datetime]::ParseExact("$($s.date) $($s.end)",'yyyy-MM-dd HH:mm',[Globalization.CultureInfo]::InvariantCulture)
  if($end -le $now){$r=Record $s; if(-not $r.saved -and -not $r.snooze){$result+=$r}}
 }}
 return @($result|Sort-Object key -Unique)
}
function Notify-Record($r){
 $w=New-Object ResizableNote; Style-Window $w 320 162; $w.Text='课后提醒'; $w.ShowInTaskbar=$false; $w.Tag=$r
 $area=[Windows.Forms.Screen]::FromControl($form).WorkingArea; $w.Location=New-Object Drawing.Point(($area.Right-$w.Width-20),($area.Bottom-$w.Height-20))
 $reminderTitle=Text-Label $w '课后提醒' 18 12 270 28; $reminderTitle.ForeColor=$slate
 [void](Text-Label $w $r.course 18 47 282 28)
 [void](Text-Label $w ($r.date+' · 回顾课堂内容与待办') 18 77 282 24)
 [void](Action $w '打开笔记' 18 115 132 {param($sender,$e) $toast=$sender.FindForm(); Edit-Record $toast.Tag; $toast.Tag.snooze=''; $script:announced[$toast.Tag.key+'|']=$true; Save-Data; $form.Show(); Reveal-Side; $toast.Close()})
 [void](Action $w '再等 10 分钟' 160 115 142 {param($sender,$e) $toast=$sender.FindForm(); $toast.Tag.snooze=(Get-Date).AddMinutes(10).ToString('o'); Save-Data; $toast.Close()})
 $w.Grip=[int](6*$scale)
 $w.MinimumSize=New-Object Drawing.Size([int](320*$scale),[int](162*$scale))
 foreach($control in $w.Controls){
  if($control -is [Windows.Forms.Label]){$control.Anchor='Top,Left,Right'}
  elseif($control -is [Windows.Forms.Button]){if($control.Left -gt 100*$scale){$control.Anchor='Bottom,Right'}else{$control.Anchor='Bottom,Left'}}
 }
 $w.Show($form); $script:toasts=@($script:toasts|Where-Object {-not $_.IsDisposed})+$w
 [System.Media.SystemSounds]::Asterisk.Play()
}
