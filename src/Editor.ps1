# Editor.ps1 — dot-sourced in Desktop.ps1 initialization order.
$side=New-Object ResizableNote; Style-Window $side 352 488; $side.Text='课堂笔记'; $side.ShowInTaskbar=$false
$sideTitle=Text-Label $side '' 20 14 262 34
$sideTitle.Font=New-Object Drawing.Font('Microsoft YaHei UI',12,[Drawing.FontStyle]::Bold)
Draggable $sideTitle $side
$sideClose=Action $side '×' 304 14 30 { Capture-Draft; $side.Hide() }
$sideClose.BackColor=$paper
$instruction=Text-Label $side '' 20 54 312 28; $instruction.ForeColor=$slate
$dates=New-Object Windows.Forms.ListBox; Place $dates 20 94 312 366
$dates.BackColor=$paper; $dates.BorderStyle='None'; $dates.Font=$font; $dates.ItemHeight=[int](32*$scale)
$side.Controls.Add($dates)
$noteLabel=Text-Label $side '课堂内容' 20 98 200 25
$noteLabel.ForeColor=$slate; $noteLabel.Font=New-Object Drawing.Font('Microsoft YaHei UI',10,[Drawing.FontStyle]::Bold)
$notes=New-Object Windows.Forms.TextBox; $notes.Multiline=$true; $notes.ScrollBars='Vertical'; $notes.BorderStyle='None'; $notes.BackColor=[Drawing.ColorTranslator]::FromHtml('#F0F3F5'); $notes.ForeColor=$ink; Place $notes 20 131 312 136; $side.Controls.Add($notes)
$taskLabel=Text-Label $side '待办事项' 20 280 312 25
$taskLabel.ForeColor=$sage; $taskLabel.Font=New-Object Drawing.Font('Microsoft YaHei UI',10,[Drawing.FontStyle]::Bold)
$tasks=New-Object Windows.Forms.TextBox; $tasks.Multiline=$true; $tasks.ScrollBars='Vertical'; $tasks.BorderStyle='None'; $tasks.BackColor=[Drawing.ColorTranslator]::FromHtml('#EFF4F0'); $tasks.ForeColor=$ink; Place $tasks 20 315 312 83; $side.Controls.Add($tasks)
$status=Text-Label $side '' 20 448 312 30; $status.ForeColor=$muted; $status.Font=New-Object Drawing.Font('Microsoft YaHei UI',9)
$save=Action $side '保存' 20 410 98 { Capture-Draft; $script:active.saved=$true; Save-Data; Show-SavedToast }
$savedToast=New-Object Windows.Forms.Label
$savedToast.Text='✓  已保存'; $savedToast.TextAlign='MiddleCenter'
$savedToast.BackColor=$sage; $savedToast.ForeColor=[Drawing.Color]::White
$savedToast.Font=New-Object Drawing.Font('Microsoft YaHei UI',10,[Drawing.FontStyle]::Bold)
$savedToast.Visible=$false; $side.Controls.Add($savedToast)
$savedToastTimer=New-Object Windows.Forms.Timer; $savedToastTimer.Interval=1500
$savedToastTimer.Add_Tick({$savedToastTimer.Stop(); $savedToast.Visible=$false})
function Show-SavedToast {
 $savedToastTimer.Stop()
 Place $savedToast (($side.ClientSize.Width/$scale-140)/2) 55 140 38
 $savedToast.Visible=$true; $savedToast.BringToFront()
 $savedToastTimer.Start()
}
$side.Add_VisibleChanged({if(-not $side.Visible){$savedToastTimer.Stop(); $savedToast.Visible=$false}})
$snooze=Action $side '10 分钟后提醒' 126 410 206 {
 Capture-Draft; $script:active.snooze=(Get-Date).AddMinutes(10).ToString('o'); Save-Data
 $status.Text='将在 '+([datetime]$script:active.snooze).ToString('HH:mm')+' 弹出提醒'; $side.Hide()
}
$save.BackColor=$sage; $save.ForeColor=[Drawing.Color]::White
$save.FlatAppearance.MouseOverBackColor=[Drawing.ColorTranslator]::FromHtml('#426253')
$save.FlatAppearance.MouseDownBackColor=[Drawing.ColorTranslator]::FromHtml('#365445')
$back=Action $side '‹' 20 14 32 {
 Capture-Draft
 if($script:editorVisible){$script:active=$null; Show-Dates}else{$side.Hide(); $form.Activate()}
}
$back.Font=New-Object Drawing.Font('Segoe UI',20)
$back.BackColor=$paper; $back.AccessibleName='返回上一级'
$editorControls=@($noteLabel,$notes,$taskLabel,$tasks,$save,$snooze)
$editorBody=New-Object Windows.Forms.Panel
$editorBody.AutoScroll=$false; $side.Controls.Add($editorBody)
foreach($c in $editorControls){$editorBody.Controls.Add($c)}
$status.Visible=$false
$notes.ScrollBars='Vertical'; $tasks.ScrollBars='Vertical'
$notes.WordWrap=$true; $tasks.WordWrap=$true
$script:editorVisible=$false; $script:manualSize=$false; $script:layingOut=$false
$side.Grip=[int](6*$scale)
function Side-Header {
 $width=$side.ClientSize.Width/$scale
 Place $back 18 12 32 36
 Place $sideTitle 60 14 ($width-116) 34
 Place $sideClose ($width-46) 14 30 32
 Place $instruction 20 54 ($width-40) 28
 $back.Visible=$true
}
function Fit-Dates {
 if($script:layingOut){return}
 $script:layingOut=$true
 try {
  $side.MinimumSize=New-Object Drawing.Size([int](320*$scale),[int](118*$scale))
  if(-not $script:manualSize){[void](Fit-Height $side ([int](82+[Math]::Max(1,$dates.Items.Count)*($dates.ItemHeight/$scale))))}
  Side-Header
  Place $dates 20 66 ($side.ClientSize.Width/$scale-40) ($side.ClientSize.Height/$scale-82)
 }finally{$script:layingOut=$false}
}
function Fit-Editor {
 if(-not $script:editorVisible -or $script:layingOut){return}
 $script:layingOut=$true
 try {
  $side.MinimumSize=New-Object Drawing.Size([int](320*$scale),[int](360*$scale))
  $width=$side.ClientSize.Width/$scale-40
  $wantedNote=Text-Height $notes.Text ([int]($width-18)) 52
  $wantedTask=Text-Height $tasks.Text ([int]($width-18)) 42
  if(-not $script:manualSize){[void](Fit-Height $side ([int](250+$wantedNote+$wantedTask)))}
  $height=$side.ClientSize.Height/$scale
  $available=[Math]::Max(94,$height-250)
  $noteHeight=[Math]::Max(52,[Math]::Min($available-42,$available*$wantedNote/($wantedNote+$wantedTask)))
  $taskHeight=$available-$noteHeight
  Side-Header
  Place $editorBody 20 98 $width ($height-110)
  Place $noteLabel 0 0 $width 26
  Place $notes 0 34 $width $noteHeight
  $taskY=34+$noteHeight+16
  Place $taskLabel 0 $taskY $width 26
  Place $tasks 0 ($taskY+34) $width $taskHeight
  $buttonY=$taskY+34+$taskHeight+16
  Place $save 0 $buttonY 88 32
  Place $snooze 98 $buttonY ($width-98) 32
  $status.Visible=$false
 }finally{$script:layingOut=$false}
}
$side.Add_ResizeBegin({$script:manualSize=$true})
$side.Add_Resize({if($script:editorVisible){Fit-Editor}else{Fit-Dates}})
$dates.DrawMode='OwnerDrawFixed'; $dates.ItemHeight=[int](38*$scale); $dates.IntegralHeight=$false
$dates.Add_DrawItem({param($sender,$e)
 if($e.Index -lt 0){return}
 $selected=($e.State -band [Windows.Forms.DrawItemState]::Selected) -ne 0
 $brush=New-Object Drawing.SolidBrush($(if($selected){$soft}else{$paper}))
 $e.Graphics.FillRectangle($brush,$e.Bounds); $brush.Dispose()
 $rect=$e.Bounds; $rect.X+=[int](10*$scale); $rect.Width-=[int](20*$scale)
 [Windows.Forms.TextRenderer]::DrawText($e.Graphics,[string]$sender.Items[$e.Index],$font,$rect,$ink,([Windows.Forms.TextFormatFlags]::VerticalCenter -bor [Windows.Forms.TextFormatFlags]::EndEllipsis -bor [Windows.Forms.TextFormatFlags]::NoPrefix))
})
foreach($box in @($notes,$tasks)){$box.Add_TextChanged({if(-not $script:loading -and $script:editorVisible){Fit-Editor}})}
function Has-RecordContent($r) {
 if(-not [string]::IsNullOrWhiteSpace([string]$r.notes)){return $true}
 return @($r.tasks|Where-Object {-not [string]::IsNullOrWhiteSpace([string]$_.text)}).Count -gt 0
}
function Show-Dates {
 $script:editorVisible=$false; $script:manualSize=$false; $editorBody.Visible=$false
 foreach($c in $editorControls){$c.Visible=$false}; $dates.Visible=$true
 $instruction.Text=''; $instruction.Visible=$false; $sideTitle.Text=$script:course
 $dates.Items.Clear()
 $today=Get-Date -Format 'yyyy-MM-dd'
 $todayDates=@($script:db.schedule|Where-Object {$_.course -eq $script:course -and $_.date -eq $today}|ForEach-Object {$_.date})
 $recordDates=@($script:db.records|Where-Object {
  $_.course -eq $script:course -and $_.date -le $today -and ($_.date -eq $today -or (Has-RecordContent $_))
 }|ForEach-Object {$_.date})
 $script:dateKeys=@($todayDates+$recordDates|Sort-Object -Unique -Descending)
 foreach($d in $script:dateKeys) { [void]$dates.Items.Add($d) }
 Fit-Dates
}
function Edit-Record($r) {
 Capture-Draft; $script:loading=$true; $script:active=$r; $script:course=$r.course
 $sideTitle.Text=$r.course; $instruction.Text=$r.date; $instruction.Visible=$true
 $notes.Text=$r.notes; $tasks.Text=(@($r.tasks|ForEach-Object {$_.text}) -join "`r`n")
 $dates.Visible=$false; foreach($c in $editorControls){$c.Visible=$true}; $status.Visible=$false
 $script:loading=$false; $script:editorVisible=$true; $script:manualSize=$false; $editorBody.Visible=$true
 $editorBody.AutoScrollPosition=New-Object Drawing.Point(0,0); Fit-Editor
}
$animation=New-Object Windows.Forms.Timer; $animation.Interval=15
$script:slideStep=0
function Position-Side {
 $area=[Windows.Forms.Screen]::FromControl($form).WorkingArea; $gap=[int](8*$scale)
 $script:targetX=if($form.Right+$gap+$side.Width -le $area.Right){$form.Right+$gap}else{[Math]::Max($area.Left,$form.Left-$side.Width-$gap)}
 $script:targetY=[Math]::Max($area.Top,[Math]::Min($form.Top,$area.Bottom-$side.Height))
}
function Reveal-Side {
 $animation.Stop()
 Position-Side
 if($side.Visible){
  $side.Opacity=1
  $side.Location=New-Object Drawing.Point([int]$script:targetX,[int]$script:targetY)
  $side.BringToFront(); $side.Activate()
  return
 }
 $script:slideStep=0
 $script:slideFrom=$script:targetX+$(if($script:targetX -gt $form.Left){-28*$scale}else{28*$scale})
 $side.Location=New-Object Drawing.Point([int]$script:slideFrom,[int]$script:targetY)
 $side.Opacity=0; $side.Owner=$form; $side.Show(); $animation.Start()
}
$animation.Add_Tick({
 $script:slideStep++; $p=[Math]::Min(1,$script:slideStep/12.0); $ease=1-[Math]::Pow(1-$p,3)
 $side.Left=[int]($script:slideFrom+($script:targetX-$script:slideFrom)*$ease); $side.Opacity=$p
 if($p -ge 1){$animation.Stop()}
})
$form.Add_LocationChanged({if($side.Visible){Position-Side; $side.Location=New-Object Drawing.Point([int]$script:targetX,[int]$script:targetY)}})
function Open-Course($name) { Capture-Draft; $script:active=$null; $script:course=$name; Show-Dates; Reveal-Side }
$courses.Add_DoubleClick({if($courses.SelectedIndex -ge 0){Open-Course ([string]$courses.SelectedItem)}})
function Open-Date {
 if($dates.SelectedIndex -lt 0){return}
 $d=$script:dateKeys[$dates.SelectedIndex]
 $rows=@($script:db.schedule|Where-Object {$_.course -eq $script:course -and $_.date -eq $d})
 foreach($row in $rows){[void](Record $row)}
 $rs=@($script:db.records|Where-Object {$_.course -eq $script:course -and $_.date -eq $d}|Sort-Object start)
 if($rs.Count -eq 1){Edit-Record $rs[0]}
 elseif($rs.Count -gt 1){
  $pick=New-Object Windows.Forms.ContextMenuStrip
  foreach($r in $rs){$i=$pick.Items.Add("$($r.start)  本日第 $($pick.Items.Count+1) 节"); $i.Tag=$r; $i.Add_Click({param($sender,$e) Edit-Record $sender.Tag})}
  $pick.Show($dates,(New-Object Drawing.Point(10,10)))
 }
}
$dates.Add_DoubleClick({Open-Date}); $dates.Add_KeyDown({param($sender,$e) if($e.KeyCode -eq 'Enter'){Open-Date}})
