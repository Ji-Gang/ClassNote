# Ui.ps1 — dot-sourced in Desktop.ps1 initialization order.
$paper=[Drawing.ColorTranslator]::FromHtml('#FAF9F5')
$ink=[Drawing.ColorTranslator]::FromHtml('#303C43')
$muted=[Drawing.ColorTranslator]::FromHtml('#727D80')
$soft=[Drawing.ColorTranslator]::FromHtml('#E7EEEB')
$accent=[Drawing.ColorTranslator]::FromHtml('#527567')
$font=New-Object Drawing.Font('Microsoft YaHei UI',10)
$slate=[Drawing.ColorTranslator]::FromHtml('#587389')
$sage=[Drawing.ColorTranslator]::FromHtml('#527567')
$line=[Drawing.ColorTranslator]::FromHtml('#E2E7E3')
$form=New-Object ResizableNote
$g=$form.CreateGraphics(); $scale=$g.DpiX/96; $g.Dispose()
function Place($c,$x,$y,$w,$h) { $c.SetBounds([int]($x*$scale),[int]($y*$scale),[int]($w*$scale),[int]($h*$scale)) }
function Style-Window($w,$width,$height) {
 $w.Font=$font; $w.BackColor=$paper; $w.ForeColor=$ink; $w.AutoScaleMode='None'
 $w.ShowInTaskbar=$false; $w.FormBorderStyle='None'; $w.StartPosition='Manual'; $w.TopMost=[bool]$script:db.pinned
 $w.ClientSize=New-Object Drawing.Size([int]($width*$scale),[int]($height*$scale))
 $w.Add_Paint({param($sender,$e)
  $pen=New-Object Drawing.Pen($line,[single]$scale)
  $e.Graphics.DrawRectangle($pen,0,0,($sender.ClientSize.Width-1),($sender.ClientSize.Height-1)); $pen.Dispose()
 })
}
function Fit-Height($w,[int]$desired) {
 $area=[Windows.Forms.Screen]::FromControl($form).WorkingArea
 $limit=[int][Math]::Min(640,[Math]::Floor(($area.Height*0.78)/$scale))
 $height=[Math]::Min($desired,$limit)
 $w.ClientSize=New-Object Drawing.Size($w.ClientSize.Width,[int]($height*$scale))
 if($w.Visible){$w.Top=[Math]::Max($area.Top,[Math]::Min($w.Top,$area.Bottom-$w.Height))}
 return $height
}
function Text-Height([string]$text,[int]$width,[int]$minimum) {
 if(-not $text){return $minimum}
 $size=[Windows.Forms.TextRenderer]::MeasureText($text+"`r`n",$font,(New-Object Drawing.Size([int]($width*$scale),[int]::MaxValue)),([Windows.Forms.TextFormatFlags]::WordBreak -bor [Windows.Forms.TextFormatFlags]::TextBoxControl -bor [Windows.Forms.TextFormatFlags]::NoPadding))
 return [int][Math]::Max($minimum,[Math]::Ceiling($size.Height/$scale)+8)
}
function Text-Label($parent,$text,$x,$y,$w,$h) {
 $c=New-Object Windows.Forms.Label; $c.Text=$text; $c.AutoEllipsis=$true; $c.TextAlign='MiddleLeft'
 Place $c $x $y $w $h
 if($y -le 18){$c.Font=New-Object Drawing.Font('Microsoft YaHei UI',12,[Drawing.FontStyle]::Bold)}
 $parent.Controls.Add($c); return $c
}
function Action($parent,$text,$x,$y,$w,$action) {
 $c=New-Object Windows.Forms.Button; $c.Text=$text; Place $c $x $y $w 32
 $c.FlatStyle='Flat'; $c.FlatAppearance.BorderSize=0; $c.BackColor=$soft; $c.ForeColor=$ink
 $c.FlatAppearance.MouseOverBackColor=[Drawing.ColorTranslator]::FromHtml('#DDE7E1')
 $c.FlatAppearance.MouseDownBackColor=[Drawing.ColorTranslator]::FromHtml('#CDDCD3')
 $c.Cursor=[Windows.Forms.Cursors]::Default; $c.Add_Click($action); $parent.Controls.Add($c); return $c
}
function Draggable($c,$target) {
 $c.Tag=$target
 $c.Add_MouseDown({param($sender,$e) if ($e.Button -eq 'Left') { [void][NoteNative]::ReleaseCapture(); [void][NoteNative]::SendMessage($sender.Tag.Handle,0xA1,[IntPtr]2,[IntPtr]::Zero) }})
}
