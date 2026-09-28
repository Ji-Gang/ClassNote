function Expand-Timetable($config) {
 $monday=[datetime]::ParseExact($config.week1Monday,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)
 if($monday.DayOfWeek -ne 'Monday'){throw '学期起点必须为周一'}
 foreach($rule in $config.rules){foreach($week in $rule.weeks){
  $date=$monday.AddDays(($week-1)*7+$rule.weekday-1).ToString('yyyy-MM-dd')
  $first=$config.periodTimes.PSObject.Properties[[string]$rule.periodStart]
  $last=$config.periodTimes.PSObject.Properties[[string]$rule.periodEnd]
  $start=''; $end=''
  if($first -and $last){$start=$first.Value.start; $end=$last.Value.end}
  if($config.PSObject.Properties['blocks']){
   $block=$config.blocks.PSObject.Properties["$($rule.periodStart)-$($rule.periodEnd)"]
   if($block){$start=$block.Value.start; $end=$block.Value.end}
  }
  [pscustomobject]@{date=$date;course=$rule.course;start=$start;end=$end;periodStart=$rule.periodStart;periodEnd=$rule.periodEnd;week=$week;sourceId="sjtu|$date|$($rule.course)|$($rule.periodStart)-$($rule.periodEnd)"}
 }}
}
function Update-LocalTimetable {
 if($script:db.PSObject.Properties['scheduleSource'] -and $script:db.scheduleSource -in @('csv','manual')){return}
 $rulesPath=Join-Path $PSScriptRoot 'timetable-rules.json'
 if(-not (Test-Path $rulesPath)){return}
 $config=Get-Content $rulesPath -Raw -Encoding UTF8|ConvertFrom-Json
 if($script:db.PSObject.Properties['timetableVersion'] -and $script:db.timetableVersion -eq $config.version){return}
 $rows=@(Expand-Timetable $config | Sort-Object date,periodStart)
 if(-not $rows.Count){throw '课表规则没有生成课程'}
 $script:db.schedule=$rows; $script:db.demo=$false
 if(-not $script:db.PSObject.Properties['timetableVersion']){$script:db|Add-Member -NotePropertyName timetableVersion -NotePropertyValue $config.version}else{$script:db.timetableVersion=$config.version}
 Save-Data
}
