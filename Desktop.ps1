# Application entry point. Keep data paths rooted here, not in the src directory.
$ErrorActionPreference = 'Stop'
$script:appRoot = $PSScriptRoot

# Modules share application state intentionally; load order follows UI dependencies.
$modules = @(
    'Native.ps1',
    'Bootstrap.ps1',
    'Ui.ps1',
    'Storage.ps1',
    'MainWindow.ps1',
    'Editor.ps1',
    'Todos.ps1',
    'Archive.ps1',
    'Menu.ps1',
    'Reminders.ps1',
    'Lifecycle.ps1'
)
foreach ($module in $modules) {
    . (Join-Path $script:appRoot "src\$module")
}