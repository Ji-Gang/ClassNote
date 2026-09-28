# Archive.ps1 — dot-sourced in Desktop.ps1 initialization order.
function Fit-Archive($tree) {
 $rows=0
 foreach($n in $tree.Nodes){$rows++; if($n.IsExpanded){$rows+=$n.Nodes.Count}}
 $window=$tree.FindForm()
 if(-not $window.UserResized){[void](Fit-Height $window ([int](80+[Math]::Max(1,$rows)*($tree.ItemHeight/$scale))))}
 Place $tree 20 64 ($window.ClientSize.Width/$scale-40) ($window.ClientSize.Height/$scale-80)
}
function Show-ArchivePreview($entry) {
 $w=New-Object ResizableNote; Style-Window $w 370 400; $w.Text='课堂记录预览'; $w.StartPosition='CenterScreen'
 $w.Grip=[int](6*$scale); $w.MinimumSize=New-Object Drawing.Size([int](300*$scale),[int](280*$scale))
 $title=Text-Label $w $entry.course 20 14 280 34; $title.Anchor='Top,Left,Right'; Draggable $title $w
 $close=Action $w '×' 322 14 28 {param($sender,$e)$sender.FindForm().Close()}; $close.Anchor='Top,Right'; $close.BackColor=$paper
 $date=Text-Label $w $entry.date 20 54 330 28; $date.ForeColor=$slate
 $noteTitle=Text-Label $w '课堂内容' 20 94 330 26; $noteTitle.ForeColor=$slate
 $taskTitle=Text-Label $w '待办事项' 20 244 330 26; $taskTitle.ForeColor=$sage
 $noteView=New-Object Windows.Forms.TextBox; $taskView=New-Object Windows.Forms.TextBox
 foreach($box in @($noteView,$taskView)){
  $box.Multiline=$true; $box.ReadOnly=$true; $box.WordWrap=$true; $box.ScrollBars='Vertical'
  $box.BorderStyle='None'; $box.BackColor=$paper; $box.ForeColor=$ink; $w.Controls.Add($box)
 }
 $noteView.AccessibleName='只读课堂内容'; $taskView.AccessibleName='只读待办事项'
 $noteParts=@(); $taskParts=@()
 foreach($record in @($entry.records|Sort-Object start)){
  $prefix=if($entry.records.Count -gt 1 -and $record.start){"$($record.start)–$($record.end)`r`n"}else{''}
  if(-not [string]::IsNullOrWhiteSpace($record.notes)){$noteParts+=($prefix+$record.notes)}
  $items=@($record.tasks|Where-Object {-not [string]::IsNullOrWhiteSpace($_.text)}|ForEach-Object {$(if($_.done){'✓  '}else{'○  '})+$_.text})
  if($items.Count){$taskParts+=($prefix+($items -join "`r`n"))}
 }
 $noteView.Text=if($noteParts.Count){$noteParts -join "`r`n`r`n"}else{'暂无课堂内容'}
 $taskView.Text=if($taskParts.Count){$taskParts -join "`r`n`r`n"}else{'暂无待办事项'}
 $w.Tag=[pscustomobject]@{notes=$noteView;tasks=$taskView;taskTitle=$taskTitle}
 $w.Add_Resize({param($sender,$e)Layout-ArchivePreview $sender})
 Layout-ArchivePreview $w
 $w.Show($form)
}
function Layout-ArchivePreview($window) {
 $meta=$window.Tag; if(-not $meta){return}
 $width=$window.ClientSize.Width/$scale-40
 $available=$window.ClientSize.Height/$scale-180
 $noteHeight=[Math]::Floor($available*0.6); $taskY=130+$noteHeight+16
 Place $meta.notes 20 130 $width $noteHeight
 Place $meta.taskTitle 20 $taskY $width 26
 Place $meta.tasks 20 ($taskY+32) $width ($window.ClientSize.Height/$scale-$taskY-52)
}
function Show-Archive {
 Capture-Draft; $w=New-Object ResizableNote; Style-Window $w 350 420; $w.Text='日期档案'; $w.StartPosition='CenterScreen'
 $t=Text-Label $w '日期档案' 20 14 270 32; Draggable $t $w
 [void](Action $w '×' 300 14 30 {param($sender,$e)$sender.FindForm().Close()})
 $tree=New-Object Windows.Forms.TreeView; Place $tree 20 64 310 336; $tree.BackColor=$paper; $tree.BorderStyle='None'; $tree.ItemHeight=[int](32*$scale); $tree.ShowLines=$false; $tree.ShowPlusMinus=$false; $tree.ShowRootLines=$false
 $tree.DrawMode='OwnerDrawAll'; $tree.FullRowSelect=$true
 $tree.Add_DrawNode({param($sender,$e)
  $rect=New-Object Drawing.Rectangle(0,$e.Bounds.Y,$sender.ClientSize.Width,$e.Bounds.Height)
  $selected=$sender.SelectedNode -eq $e.Node
  $brush=New-Object Drawing.SolidBrush($(if($selected){$soft}else{$paper}))
  $e.Graphics.FillRectangle($brush,$rect); $brush.Dispose()
  $indent=if($e.Node.Level -eq 0){28}else{42}
  if($e.Node.Nodes.Count -gt 0){
   $x=[int](12*$scale); $y=$rect.Y+[int]($rect.Height/2)
   $pen=New-Object Drawing.Pen($muted,[single](1.5*$scale))
   if($e.Node.IsExpanded){
    $e.Graphics.DrawLine($pen,$x-4*$scale,$y-2*$scale,$x,$y+2*$scale)
    $e.Graphics.DrawLine($pen,$x,$y+2*$scale,$x+4*$scale,$y-2*$scale)
   }else{
    $e.Graphics.DrawLine($pen,$x-2*$scale,$y-4*$scale,$x+2*$scale,$y)
    $e.Graphics.DrawLine($pen,$x+2*$scale,$y,$x-2*$scale,$y+4*$scale)
   }; $pen.Dispose()
  }
  $rect.X=[int]($indent*$scale); $rect.Width-=$rect.X
  [Windows.Forms.TextRenderer]::DrawText($e.Graphics,$e.Node.Text,$font,$rect,$ink,([Windows.Forms.TextFormatFlags]::VerticalCenter -bor [Windows.Forms.TextFormatFlags]::EndEllipsis -bor [Windows.Forms.TextFormatFlags]::NoPrefix))
 })
 $tree.Add_NodeMouseClick({param($sender,$e)if($e.Node.Nodes.Count -gt 0 -and $e.X -lt 28*$scale){$e.Node.Toggle()}})
 $w.Controls.Add($tree)
 foreach($group in @($script:db.records|Where-Object {$_.date -le (Get-Date -Format 'yyyy-MM-dd') -and (Has-RecordContent $_)}|Group-Object date|Sort-Object Name -Descending)){
  $node=$tree.Nodes.Add($group.Name)
  foreach($courseGroup in @($group.Group|Group-Object course|Sort-Object Name)){
   $child=$node.Nodes.Add($courseGroup.Name)
   $child.Tag=[pscustomobject]@{course=$courseGroup.Name;date=$group.Name;records=@($courseGroup.Group)}
  }
 }
 $tree.Add_NodeMouseDoubleClick({param($sender,$e)if($e.Node.Tag){Show-ArchivePreview $e.Node.Tag}})
 $tree.Add_KeyDown({param($sender,$e)if($e.KeyCode -eq 'Enter' -and $sender.SelectedNode -and $sender.SelectedNode.Tag){Show-ArchivePreview $sender.SelectedNode.Tag}})
 $tree.Add_AfterExpand({param($sender,$e)Fit-Archive $sender})
 $tree.Add_AfterCollapse({param($sender,$e)Fit-Archive $sender})
 Fit-Archive $tree
 $w.Grip=[int](6*$scale)
 $w.MinimumSize=New-Object Drawing.Size([int](300*$scale),[int](130*$scale))
 $tree.Anchor='Top,Bottom,Left,Right'
 $t.Anchor='Top,Left,Right'; $t.Width=[int](240*$scale)
 foreach($control in $w.Controls){if($control -is [Windows.Forms.Button]){$control.Anchor='Top,Right'}}
 $w.Show($form)
}
