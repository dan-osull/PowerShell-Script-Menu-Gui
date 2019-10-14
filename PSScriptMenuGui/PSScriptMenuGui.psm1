if ($PSEdition -eq 'Core') {
    if (-not $IsWindows) {
        throw 'This module only runs on Windows'
    }
    if ($PSVersionTable.PSVersion.Major -eq 6) {
        throw 'This module is not compatible with PowerShell Core 6'
    }
}

# Get public and private function definition files
# Based on: https://github.com/RamblingCookieMonster/PSStackExchange/blob/db1277453374cb16684b35cf93a8f5c97288c41f/PSStackExchange/PSStackExchange.psm1
$scripts = @()
$scripts += Get-ChildItem -Path $PSScriptRoot\public\*.ps1 -ErrorAction SilentlyContinue
$scripts += Get-ChildItem -Path $PSScriptRoot\private\*.ps1 -ErrorAction SilentlyContinue

# Dot source the files
ForEach ($script in $scripts) {
    try {
        . $script.FullName
    }
    catch {
        throw
    }
}

# Used to get files from xaml and examples subfolders
$moduleRoot = $PSScriptRoot