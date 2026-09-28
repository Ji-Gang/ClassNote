function Assert($condition,$message){if(-not $condition){throw $message}}
$form.Show()
Assert ($courses.Items.Count -eq 5) 'Startup fixture failed'
Open-CourseTodo '示例课程一'; Reveal-Side; Reveal-Side
$notes.Text='测试笔记'; $tasks.Text="第一项`r`n第二项"; $save.PerformClick()
Assert ($savedToast.Visible -and $script:active.saved) 'Save/toast failed'
$stamp=(Get-Item $script:path).LastWriteTimeUtc
Capture-Draft
Assert ((Get-Item $script:path).LastWriteTimeUtc -eq $stamp) 'Unchanged draft wrote data'
Show-Todos
$flow=$script:todoWindow.Controls|Where-Object {$_ -is [Windows.Forms.FlowLayoutPanel]}
$row=@($flow.Controls|Where-Object {$_ -is [NoteCheck]})[0]
$row.Checked=$true
Assert $script:active.tasks[0].done 'Todo completion failed'
Select-Todo $row; $script:todoWindow.Tag.PerformClick(); Capture-Draft
Assert ($script:active.tasks.Count -eq 1 -and $tasks.Text -eq '第二项') 'Deletion/editor sync failed'
Show-AllCourses
$all=@([Windows.Forms.Application]::OpenForms|Where-Object {$_.Text -eq '全部课程'})[0]
$list=$all.Controls|Where-Object {$_ -is [Windows.Forms.ListBox]}
$list.SelectedIndex=1; $name=$list.SelectedItem; Move-Course $list -1
Assert (@(Ordered-Courses)[0] -eq $name) 'Course ordering failed'
$notes.Text=(('多行笔记'+"`r`n")*70); Fit-Editor
Assert (-not $editorBody.AutoScroll -and $notes.ScrollBars -eq 'Vertical') 'Column scroll failed'
$form.ClientSize=New-Object Drawing.Size([int](420*$scale),[int](410*$scale))
Assert ($more.Right -le $form.ClientSize.Width) 'Main resize failed'
$script:active.saved=$true; $script:active.snooze=(Get-Date).AddSeconds(-2).ToString('o')
Assert (@(Get-DueRecords (Get-Date)).Count -eq 1) 'Saved-note reminder failed'
Notify-Record $script:active
Assert ($form.Enabled -and $side.Enabled) 'Reminder is modal'
$form.Close()
Assert (-not $form.IsDisposed -and $tray.Visible) 'Close should preserve tray'
$form.Show()
$disk=Get-Content $script:path -Raw -Encoding UTF8|ConvertFrom-Json
Assert ($disk.records.Count -gt 0 -and $disk.courseOrder[0] -eq $name) 'Persistence failed'
# Archive only includes authored content, including today; opens a separate read-only preview.
$empty=Record ([pscustomobject]@{course='空白测试课程';date=(Get-Date -Format 'yyyy-MM-dd');start='';end=''})
Show-Archive
$archive=@([Windows.Forms.Application]::OpenForms|Where-Object {$_.Text -eq '日期档案'})[0]
$tree=$archive.Controls|Where-Object {$_ -is [Windows.Forms.TreeView]}
$children=@($tree.Nodes|ForEach-Object {$_.Nodes}|ForEach-Object {$_})
Assert (@($children|Where-Object {$_.Text -eq '空白测试课程'}).Count -eq 0) 'Empty archive course visible'
$entry=@($children|Where-Object {$_.Text -eq '示例课程一'})[0].Tag
$beforeKey=$script:active.key
Show-ArchivePreview $entry
$preview=@([Windows.Forms.Application]::OpenForms|Where-Object {$_.Text -eq '课堂记录预览'})[0]
Assert ($preview.Tag.notes.ReadOnly -and $preview.Tag.tasks.ReadOnly) 'Archive preview is editable'
Assert ($preview.Tag.tasks.Text.Contains('第二项') -and $script:active.key -eq $beforeKey) 'Preview changed active editor or wrong content'
$preview.Height+=120
Assert ($preview.Tag.tasks.Bottom -le $preview.ClientSize.Height) 'Preview resize clipped content'
$script:quitting=$true
foreach($window in @([Windows.Forms.Application]::OpenForms)){$window.Close()}
Write-Output 'PASS: startup, notes, unchanged draft, toast, todos, delete, ordering, resize, reminders, tray and persistence'
