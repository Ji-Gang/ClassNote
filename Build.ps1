$ErrorActionPreference='Stop'
$compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if(-not(Test-Path $compiler)){$compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'}
& $compiler /nologo /target:winexe /reference:System.Windows.Forms.dll "/out:$PSScriptRoot\ClassNote.exe" "$PSScriptRoot\Launcher.cs"
if($LASTEXITCODE -ne 0){throw 'Launcher build failed'}
