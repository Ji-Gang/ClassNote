function Open-CourseTodo([string]$course) {
 Capture-Draft
 $today=Get-Date -Format 'yyyy-MM-dd'
 $existing=@($script:db.records|Where-Object {$_.course -eq $course -and $_.date -eq $today}|Sort-Object start)
 if($existing.Count){$record=$existing[0]}
 else{
  $lesson=@($script:db.schedule|Where-Object {$_.course -eq $course -and $_.date -eq $today}|Sort-Object start)|Select-Object -First 1
  if(-not $lesson){$lesson=[pscustomobject]@{date=$today;course=$course;start='';end='';sourceId="note|$today|$course"}}
  $record=Record $lesson
 }
 Edit-Record $record
 Reveal-Side
 [void]$tasks.Focus()
}
function Ordered-Courses {
 $available=@($script:db.schedule|Select-Object -ExpandProperty course|Sort-Object -Unique)
 $seen=@{}
 if($script:db.PSObject.Properties['courseOrder']){
  foreach($name in $script:db.courseOrder){if($name -in $available -and -not $seen.ContainsKey($name)){$seen[$name]=$true; $name}}
 }
 foreach($name in $available){if(-not $seen.ContainsKey($name)){$seen[$name]=$true; $name}}
}
function Move-Course($list,[int]$direction) {
 $index=$list.SelectedIndex; $target=$index+$direction
 if($index -lt 0 -or $target -lt 0 -or $target -ge $list.Items.Count){return}
 $name=$list.Items[$index]
 $list.Items.RemoveAt($index); $list.Items.Insert($target,$name); $list.SelectedIndex=$target
 $script:db|Add-Member -NotePropertyName courseOrder -NotePropertyValue @($list.Items|ForEach-Object {[string]$_}) -Force
 Save-Data
}
function Show-AllCourses {
 $w=New-Object ResizableNote; Style-Window $w 352 420; $w.Text='全部课程'; $w.StartPosition='CenterScreen'
 $w.Grip=[int](6*$scale); $w.MinimumSize=New-Object Drawing.Size([int](300*$scale),[int](180*$scale))
 $title=Text-Label $w '全部课程' 20 14 260 34; Draggable $title $w
 $close=Action $w '×' 304 14 28 {param($sender,$e)$sender.FindForm().Close()}; $close.Anchor='Top,Right'; $close.BackColor=$paper
 $list=New-Object Windows.Forms.ListBox; Place $list 20 66 312 286; $list.Anchor='Top,Bottom,Left,Right'
 $list.BackColor=$paper; $list.ForeColor=$ink; $list.BorderStyle='None'; $list.IntegralHeight=$false; $list.DrawMode='OwnerDrawFixed'; $list.ItemHeight=[int](40*$scale)
 $list.Add_DrawItem({param($sender,$e)
  if($e.Index -lt 0){return}
  $selected=($e.State -band [Windows.Forms.DrawItemState]::Selected) -ne 0
  $brush=New-Object Drawing.SolidBrush($(if($selected){$soft}else{$paper})); $e.Graphics.FillRectangle($brush,$e.Bounds); $brush.Dispose()
  $rect=$e.Bounds; $rect.X+=[int](10*$scale); $rect.Width-=[int](20*$scale)
  [Windows.Forms.TextRenderer]::DrawText($e.Graphics,[string]$sender.Items[$e.Index],$font,$rect,$ink,([Windows.Forms.TextFormatFlags]::VerticalCenter -bor [Windows.Forms.TextFormatFlags]::EndEllipsis))
 })
 foreach($name in @(Ordered-Courses)){[void]$list.Items.Add($name)}
 $up=Action $w '↑ 上移' 20 368 100 {param($sender,$e)Move-Course $sender.Tag -1}
 $down=Action $w '↓ 下移' 130 368 100 {param($sender,$e)Move-Course $sender.Tag 1}
 $up.Tag=$list; $down.Tag=$list; $up.Anchor='Bottom,Left'; $down.Anchor='Bottom,Left'
 $up.Enabled=$false; $down.Enabled=$false
 $list.Tag=[pscustomobject]@{up=$up;down=$down}
 $list.Add_SelectedIndexChanged({param($sender,$e)
  $sender.Tag.up.Enabled=$sender.SelectedIndex -gt 0
  $sender.Tag.down.Enabled=$sender.SelectedIndex -ge 0 -and $sender.SelectedIndex -lt $sender.Items.Count-1
 })
 $list.Add_DoubleClick({param($sender,$e)if($sender.SelectedIndex -ge 0){Open-CourseTodo ([string]$sender.SelectedItem)}})
 $list.Add_KeyDown({param($sender,$e)if($e.KeyCode -eq 'Enter' -and $sender.SelectedIndex -ge 0){Open-CourseTodo ([string]$sender.SelectedItem)}})
 $w.Controls.Add($list); $w.Show($form)
}
