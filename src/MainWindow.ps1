# MainWindow.ps1 — dot-sourced in Desktop.ps1 initialization order.
Style-Window $form 286 334; $form.Text='课程便笺'
$form.Grip=[int](6*$scale)
$form.MinimumSize=New-Object Drawing.Size([int](270*$scale),[int](220*$scale))
$screen=[Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location=New-Object Drawing.Point(($screen.Right-$form.Width-40),($screen.Top+100))
$dateLabel=Text-Label $form '' 20 16 246 34
$dateLabel.Font=New-Object Drawing.Font('Microsoft YaHei UI',12,[Drawing.FontStyle]::Bold)
Draggable $dateLabel $form
$courses=New-Object Windows.Forms.ListBox; Place $courses 14 64 258 220
$courses.BorderStyle='None'; $courses.BackColor=$paper; $courses.DrawMode='OwnerDrawFixed'
$courses.ItemHeight=[int](44*$scale); $courses.IntegralHeight=$false; $form.Controls.Add($courses)
$courses.Add_DrawItem({param($sender,$e)
 if ($e.Index -lt 0) { return }
 $selected=($e.State -band [Windows.Forms.DrawItemState]::Selected) -ne 0
 $brush=New-Object Drawing.SolidBrush($(if($selected){$soft}else{$paper}))
 $e.Graphics.FillRectangle($brush,$e.Bounds); $brush.Dispose()
 $colors=@('#6E8C7D','#71879D','#A58F72','#8A819C','#80938A')
 $dot=New-Object Drawing.SolidBrush([Drawing.ColorTranslator]::FromHtml($colors[$e.Index%$colors.Count]))
 $e.Graphics.SmoothingMode='AntiAlias'
 $e.Graphics.FillEllipse($dot,[single](10*$scale),[single]($e.Bounds.Y+$e.Bounds.Height/2-3*$scale),[single](6*$scale),[single](6*$scale)); $dot.Dispose()
 $rect=$e.Bounds; $rect.X += [int](28*$scale); $rect.Width -= [int](40*$scale)
 [Windows.Forms.TextRenderer]::DrawText($e.Graphics,[string]$sender.Items[$e.Index],$font,$rect,$ink,([Windows.Forms.TextFormatFlags]::VerticalCenter -bor [Windows.Forms.TextFormatFlags]::EndEllipsis -bor [Windows.Forms.TextFormatFlags]::NoPrefix))
})
function Refresh-Courses {
 $courses.Items.Clear(); $dateLabel.Text=Get-Date -Format 'MM月dd日  dddd'
 $names=@($script:db.schedule|Where-Object {$_.date -eq (Get-Date -Format 'yyyy-MM-dd')}|Sort-Object periodStart,start|Select-Object -ExpandProperty course -Unique)
 foreach ($name in $names) { [void]$courses.Items.Add($name) }
 if ($names.Count -eq 0) { $dateLabel.Text=(Get-Date -Format 'MM月dd日')+' · 今日无课' }
}
