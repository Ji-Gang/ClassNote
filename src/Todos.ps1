# Todos.ps1 — dot-sourced in Desktop.ps1 initialization order.
function Course-DisplayName([string]$name) {
 if($name -match '^主修课程[一二三四五]$'){return '未归类'}
 return $name
}
function Show-Todos {
 Capture-Draft
 if($script:todoWindow -and -not $script:todoWindow.IsDisposed){$script:todoWindow.Close()}
 $w=New-Object ResizableNote; Style-Window $w 370 450; $w.Text='待办事项'
 $w.StartPosition='CenterScreen'; $script:todoWindow=$w
 $t=Text-Label $w '待办事项' 20 14 280 32; $t.Font=$sideTitle.Font; Draggable $t $w
 $x=Action $w '×' 316 14 34 {param($sender,$e) $sender.FindForm().Close()}; $x.BackColor=$paper
 [void](Action $w '刷新' 238 14 68 {Show-Todos})
 $delete=Action $w '删除' 158 14 68 {
  param($sender,$e)
  if(-not $sender.Tag){return}
  Remove-Todo $sender.Tag
  Show-Todos
 }
 $delete.ForeColor=[Drawing.ColorTranslator]::FromHtml('#A3534B')
 $delete.BackColor=[Drawing.ColorTranslator]::FromHtml('#F5E9E6')
 $delete.Visible=$false
 $w.Tag=$delete
 $flow=New-Object Windows.Forms.FlowLayoutPanel; Place $flow 20 64 330 336; $flow.AutoScroll=$true; $flow.FlowDirection='TopDown'; $flow.WrapContents=$false; $w.Controls.Add($flow)
 $groups=@($script:db.records|Where-Object {$_.tasks.Count -gt 0}|Group-Object date|Sort-Object Name -Descending)
 foreach($group in $groups){
  $day=New-Object Windows.Forms.Label; $day.Text=$group.Name; $day.ForeColor=$slate; $day.Size=New-Object Drawing.Size([int](300*$scale),[int](32*$scale)); $flow.Controls.Add($day)
  foreach($r in $group.Group){foreach($task in $r.tasks){
   $cb=New-Object NoteCheck; $cb.Text="$($task.text)    $(Course-DisplayName $r.course)"; $cb.Checked=[bool]$task.done
   $cb.Size=New-Object Drawing.Size([int](300*$scale),[int]((Text-Height $cb.Text 274 40)*$scale)); $cb.Tag=[pscustomobject]@{key=$r.key;text=$task.text}
   $cb.AutoCheck=$false
   $cb.Add_MouseClick({param($sender,$e)
    if($e.X -lt 27*$scale){$sender.Checked=-not $sender.Checked; return}
    Select-Todo $sender
   })
   $cb.Add_KeyDown({param($sender,$e)
    if($e.KeyCode -eq 'Space'){$sender.Checked=-not $sender.Checked; $e.SuppressKeyPress=$true}
    elseif($e.KeyCode -eq 'Enter'){Select-Todo $sender; $e.SuppressKeyPress=$true}
   })
   $cb.Add_CheckedChanged({param($sender,$e)
    Capture-Draft
    $rec=@($script:db.records|Where-Object {$_.key -eq $sender.Tag.key})|Select-Object -First 1
    foreach($t in @($rec.tasks|Where-Object {$_.text -eq $sender.Tag.text})){$t.done=$sender.Checked}; Save-Data
   }); $flow.Controls.Add($cb)
  }}
 }
 if($groups.Count -eq 0){$empty=Text-Label $flow '暂无待办' 0 0 300 44; $empty.ForeColor=$muted}
 $contentHeight=0
 foreach($c in $flow.Controls){$contentHeight+=$c.Height+$c.Margin.Vertical}
 $h=Fit-Height $w ([int](80+[Math]::Ceiling($contentHeight/$scale)))
 Place $flow 20 64 330 ($h-80)
 $w.Grip=[int](6*$scale)
 $w.MinimumSize=New-Object Drawing.Size([int](370*$scale),[int](150*$scale))
 $flow.Anchor='Top,Bottom,Left,Right'
 foreach($control in $w.Controls){if($control -is [Windows.Forms.Button]){$control.Anchor='Top,Right'}}
 $t.Width=[int](132*$scale)
 $flow.Add_SizeChanged({param($sender,$e)
  $sender.SuspendLayout()
  $available=[Math]::Max(100,[int](($sender.ClientSize.Width-[Windows.Forms.SystemInformation]::VerticalScrollBarWidth-12)/$scale))
  foreach($row in $sender.Controls){
   $row.Width=[int]($available*$scale)
   if($row -is [NoteCheck]){$row.Height=[int]((Text-Height $row.Text ($available-29) 40)*$scale)}
  }
  $sender.ResumeLayout()
 })
 $w.Show($form)
}
function Select-Todo($control) {
 foreach($row in $control.Parent.Controls){if($row -is [NoteCheck]){$row.BackColor=$paper}}
 $control.BackColor=$soft
 $button=$control.FindForm().Tag
 $button.Tag=$control.Tag; $button.Visible=$true; $button.BringToFront()
}
function Remove-Todo($selected) {
 Capture-Draft
 $rec=@($script:db.records|Where-Object {$_.key -eq $selected.key})|Select-Object -First 1
 if(-not $rec){return}
 $items=@($rec.tasks); $remove=-1
 for($i=0;$i -lt $items.Count;$i++){if($items[$i].text -eq $selected.text){$remove=$i; break}}
 if($remove -lt 0){return}
 $rec.tasks=@(for($i=0;$i -lt $items.Count;$i++){if($i -ne $remove){$items[$i]}})
 if($script:active -and $script:active.key -eq $rec.key){
  $script:loading=$true
  try{$tasks.Text=(@($rec.tasks|ForEach-Object {$_.text}) -join "`r`n")}finally{$script:loading=$false}
  Fit-Editor
 }
 Save-Data
}
