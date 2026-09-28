$ErrorActionPreference = 'Stop'
try {
    & (Join-Path $PSScriptRoot 'Desktop.ps1')
} catch {
    $detail = ($_ | Out-String) + "`r`n" + $_.ScriptStackTrace
    $detail | Out-File (Join-Path $PSScriptRoot 'startup-error.log') -Encoding UTF8
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show("启动失败，详情已写入 startup-error.log。`n$($_.Exception.Message)",'课程便笺')
    exit 1
}
