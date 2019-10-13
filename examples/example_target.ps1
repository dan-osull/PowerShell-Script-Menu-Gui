param ($message)
"PowerShell script called from PSScriptMenuGui.ps1"
if ($message) {
    "`$message = $message"
}
$PSVersionTable
Read-Host "Press Enter to continue"