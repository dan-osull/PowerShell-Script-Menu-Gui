#region Setup
Set-Location $PSScriptRoot
Remove-Module PSScriptMenuGui -ErrorAction SilentlyContinue
try {
    Import-Module PSScriptMenuGui -ErrorAction Stop
}
catch {
    Write-Error $_
    Import-Module ..\
}
#endregion

Show-ScriptMenuGui -csvPath '.\example_data.csv' -Verbose