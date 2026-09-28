# Run in Windows PowerShell 5.1 with -STA. All mutations use a temporary fixture.
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$scratch=Join-Path ([IO.Path]::GetTempPath()) ('ClassNote-test-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $scratch|Out-Null
foreach($name in @('Desktop.ps1','CourseManager.ps1','Timetable.ps1','schedule-example.csv')){Copy-Item (Join-Path $root $name) $scratch}
Copy-Item (Join-Path $root 'src') $scratch -Recurse
$encoding=New-Object Text.UTF8Encoding($true)
$bootstrap=Join-Path $scratch 'src\Bootstrap.ps1'
$text=[IO.File]::ReadAllText($bootstrap).Replace('Local\ClassNoteDesktopFramework',('Local\ClassNoteTest'+[guid]::NewGuid().ToString('N')))
[IO.File]::WriteAllText($bootstrap,$text,$encoding)
Copy-Item (Join-Path $PSScriptRoot 'SmokeBody.ps1') $scratch
$lifecycle=Join-Path $scratch 'src\Lifecycle.ps1'
$text=[IO.File]::ReadAllText($lifecycle).Replace('[Windows.Forms.Application]::Run($form)',". (Join-Path `$script:appRoot 'SmokeBody.ps1')")
[IO.File]::WriteAllText($lifecycle,$text,$encoding)
& (Join-Path $scratch 'Desktop.ps1')
