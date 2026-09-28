# Menu.ps1 — dot-sourced in Desktop.ps1 initialization order.
function Import-Schedule {
 $dialog=New-Object Windows.Forms.OpenFileDialog; $dialog.Filter='CSV 课表|*.csv'
 if($dialog.ShowDialog() -eq 'OK'){
  try{
   $rows=@(Import-Csv $dialog.FileName -Encoding UTF8); if(-not $rows.Count){throw '课表不能为空'}; $seen=@{}
   foreach($r in $rows){
    if(-not $r.course -or -not $r.course.Trim()){throw '课程名不能为空'}
    [void][datetime]::ParseExact($r.date,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
    $a=[datetime]::ParseExact($r.start,'HH:mm',[Globalization.CultureInfo]::InvariantCulture); $b=[datetime]::ParseExact($r.end,'HH:mm',[Globalization.CultureInfo]::InvariantCulture)
    if($b -le $a){throw '结束时间须晚于开始时间'}; $k=Key $r; if($seen.ContainsKey($k)){throw '存在重复课程'}; $seen[$k]=$true
   }
   Capture-Draft
   foreach($row in $rows){
    $matches=@($script:db.schedule|Where-Object {$_.date -eq $row.date -and $_.course -eq $row.course -and $_.sourceId})
    if($matches.Count -eq 1){$row|Add-Member -NotePropertyName sourceId -NotePropertyValue $matches[0].sourceId}
   }
   $script:db|Add-Member -NotePropertyName scheduleSource -NotePropertyValue 'csv' -Force
   $script:db.schedule=$rows; $script:db.demo=$false; Save-Data; Refresh-Courses
  }catch{[void][Windows.Forms.MessageBox]::Show($_.Exception.Message,'导入失败')}
 }; $dialog.Dispose()
}
. (Join-Path $script:appRoot 'CourseManager.ps1')
$toolsMenu=New-Object Windows.Forms.ContextMenuStrip; $toolsMenu.Font=$font; $toolsMenu.BackColor=$paper
$i=$toolsMenu.Items.Add('导入课表'); $i.Add_Click({Import-Schedule})
$i=$toolsMenu.Items.Add('全部课程'); $i.Add_Click({Show-AllCourses})
$i=$toolsMenu.Items.Add('按日期查看'); $i.Add_Click({Show-Archive})
$i=$toolsMenu.Items.Add('所有待办'); $i.Add_Click({Show-Todos})
$i=$toolsMenu.Items.Add('收起便笺'); $i.Add_Click({Capture-Draft; $side.Hide(); $form.Hide()})
$i=$toolsMenu.Items.Add('退出'); $i.Add_Click({Capture-Draft; $script:quitting=$true; $form.Close()})
$more=Action $form '···' 228 292 44 { Toggle-Tools }; $more.BackColor=$paper; $more.AccessibleName='工具菜单'
# The inline flyout is a lightweight panel: no modal form or repeated Show(owner).
$flyout=New-Object Windows.Forms.Panel
Place $flyout 24 42 238 244
$flyout.BackColor=[Drawing.ColorTranslator]::FromHtml('#FFFFFF')
$flyout.Visible=$false; $form.Controls.Add($flyout)
$flyout.Add_Paint({param($sender,$e)
 $pen=New-Object Drawing.Pen([Drawing.ColorTranslator]::FromHtml('#DFE6E1'),[single]$scale)
 $e.Graphics.DrawRectangle($pen,0,0,($sender.Width-1),($sender.Height-1)); $pen.Dispose()
})
$menuCaption=Text-Label $flyout '便笺工具' 16 9 172 26
$menuCaption.Font=New-Object Drawing.Font('Microsoft YaHei UI',9)
$menuCaption.ForeColor=$muted
$menuClose=Action $flyout '×' 198 6 30 {Hide-Tools}
$menuClose.BackColor=$flyout.BackColor
function Hide-Tools { $flyout.Visible=$false; $courses.Visible=$true; $more.BackColor=$paper }
function Toggle-Tools {
 if($flyout.Visible){Hide-Tools; return}
 $courses.Visible=$false; $flyout.Visible=$true; $flyout.BringToFront(); $more.BackColor=$soft
}
function Menu-Row($text,$glyph,$y,$handler){
 $button=Action $flyout $text 10 $y 218 $handler
 Place $button 10 $y 218 38
 $button.TextAlign='MiddleLeft'
 $button.Padding=New-Object Windows.Forms.Padding([int](39*$scale),0,0,0)
 $button.BackColor=$flyout.BackColor
 $button.FlatAppearance.MouseOverBackColor=[Drawing.ColorTranslator]::FromHtml('#EDF2F0')
 $button.FlatAppearance.MouseDownBackColor=[Drawing.ColorTranslator]::FromHtml('#DFE8E3')
 $icon=New-Object Windows.Forms.Label
 $icon.Text=$glyph; $icon.Font=New-Object Drawing.Font('Segoe MDL2 Assets',12)
 $icon.ForeColor=$slate; $icon.TextAlign='MiddleCenter'
 Place $icon 8 2 28 34
 $button.Controls.Add($icon); $icon.Tag=$button
 $icon.Add_Click({param($sender,$e)$sender.Tag.PerformClick()})
 return $button
}
$menuImport=Menu-Row '导入课表' ([string][char]0xE8B5) 40 {Hide-Tools; Import-Schedule}
$menuAll=Menu-Row '全部课程' ([string][char]0xE8F1) 80 {Hide-Tools; Show-AllCourses}
$menuArchive=Menu-Row '按日期查看' ([string][char]0xE787) 120 {Hide-Tools; Show-Archive}
$menuTodos=Menu-Row '所有待办' ([string][char]0xE73A) 160 {Hide-Tools; Show-Todos}
$separator=New-Object Windows.Forms.Panel; Place $separator 16 206 206 1
$separator.BackColor=[Drawing.ColorTranslator]::FromHtml('#E6EBE7'); $flyout.Controls.Add($separator)
$menuHide=Action $flyout '收起便笺' 16 221 108 {Hide-Tools; Capture-Draft; $side.Hide(); $form.Hide()}
$menuExit=Action $flyout '退出' 134 221 88 {Hide-Tools; Capture-Draft; $script:quitting=$true; $form.Close()}
foreach($b in @($menuHide,$menuExit)){$b.BackColor=$flyout.BackColor; $b.ForeColor=$muted; $b.Font=$menuCaption.Font}
$pinToggle=Action $flyout '' 16 213 94 {
 $script:db.pinned=-not [bool]$script:db.pinned
 foreach($window in @([Windows.Forms.Application]::OpenForms)){$window.TopMost=[bool]$script:db.pinned}
 $side.TopMost=[bool]$script:db.pinned
 $pinToggle.Text=if($script:db.pinned){'置顶  开'}else{'置顶  关'}
 Save-Data
}
Place $pinToggle 16 254 88 24
$pinToggle.Font=New-Object Drawing.Font('Microsoft YaHei UI',8)
$pinToggle.BackColor=$flyout.BackColor; $pinToggle.ForeColor=$sage
$pinToggle.Text=if($script:db.pinned){'置顶  开'}else{'置顶  关'}
function Layout-Main {
 $width=$form.ClientSize.Width/$scale; $height=$form.ClientSize.Height/$scale
 Place $dateLabel 20 16 ($width-40) 34
 Place $courses 14 64 ($width-28) ($height-114)
 Place $more ($width-58) ($height-42) 44 32
 $menuHeight=[Math]::Min(284,$height-72)
 Place $flyout ($width-262) ($height-48-$menuHeight) 238 $menuHeight
 $flyout.AutoScroll=$true
 if($side.Visible){Position-Side; $side.Location=New-Object Drawing.Point([int]$script:targetX,[int]$script:targetY)}
}
$form.Add_Resize({Layout-Main})
Layout-Main
$form.Add_Deactivate({Hide-Tools})
$form.Add_MouseDown({Hide-Tools})
$dateLabel.Add_MouseDown({Hide-Tools})
$courses.Add_MouseDown({Hide-Tools})
$tray=New-Object Windows.Forms.NotifyIcon; $tray.Icon=[Drawing.SystemIcons]::Information; $tray.Text='课程便笺'; $tray.Visible=$true; $tray.ContextMenuStrip=$toolsMenu
$tray.Add_MouseClick({param($sender,$e) if($e.Button -eq [Windows.Forms.MouseButtons]::Left){$form.Show(); $form.WindowState='Normal'; $form.Activate()}})
