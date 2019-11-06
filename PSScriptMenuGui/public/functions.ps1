Function Show-ScriptMenuGui {
    <#
    .SYNOPSIS
        Use a CSV file to make a graphical menu of PowerShell scripts. Easy to customise and fast to launch.
    .DESCRIPTION
        Do you have favourite scripts that go forgotten?

        Does your organisation have scripts that would be useful to frontline staff who are not comfortable with the command line?

        This module uses a CSV file to make a graphical menu of PowerShell scripts.

        You can also add Windows programs and files to the menu.
    .PARAMETER csvPath
        Path to CSV file that defines the menu.

        See CSV reference: https://github.com/weebsnore/PowerShell-Script-Menu-Gui
    .PARAMETER windowTitle
        Custom title for the menu window.
    .PARAMETER buttonForegroundColor
        Custom button foreground (text) color.

        Hex codes (e.g. #C00077) and color names (e.g. Azure) are valid.

        See .NET Color Class: https://docs.microsoft.com/en-us/dotnet/api/system.windows.media.colors
    .PARAMETER buttonBackgroundColor
        Custom button background color.
    .PARAMETER iconPath
        Path to .ico file for use in menu.
    .PARAMETER hideConsole
        Hide the PowerShell console that the menu is called from.

        Note: This means you won't be able to see any errors from button clicks. If things aren't working, this should be the first thing you stop using.
    .PARAMETER noExit
        Start all PowerShell instances with -NoExit ("Does not exit after running startup commands.")

        Note: You can set -NoExit on individual menu items by using the Arguments column.

        See CSV reference: https://github.com/weebsnore/PowerShell-Script-Menu-Gui
    .EXAMPLE
        Show-ScriptMenuGui -csvPath '.\example_data.csv' -Verbose
    .NOTES
        Run New-ScriptMenuGuiExample to get some example files
    .LINK
        https://github.com/weebsnore/PowerShell-Script-Menu-Gui
    #>
    [CmdletBinding()]
    param(
        [string][Parameter(Mandatory)]$csvPath,
        [string]$windowTitle = 'PowerShell Script Menu',
        [string]$buttonForegroundColor = 'White',
        [string]$buttonBackgroundColor = '#366EE8',
        [string]$iconPath,
        [switch]$hideConsole,
        [switch]$noExit
    )
    Write-Verbose 'Show-ScriptMenuGui started'

    # -Verbose value, to pass to select cmdlets
    $verbose = $false
    try {
        if ($PSBoundParameters['Verbose'].ToString() -eq 'True') {
            $verbose = $true
        }
    }
    catch {}

    $csvData = Import-CSV -Path $csvPath -ErrorAction Stop
    Write-Verbose "Got $($csvData.Count) CSV rows"

    # Add unique Reference to each item
    # Used as x:Name of button and to look up action on click
    $i = 0
    $csvData | ForEach-Object {
        $_ | Add-Member -Name Reference -MemberType NoteProperty -Value "button$i"
        $i++
    }

    # Begin constructing XAML
    $xaml = Get-Content "$moduleRoot\xaml\start.xaml"
    $xaml = $xaml.Replace('INSERT_WINDOW_TITLE',$windowTitle)
    if ($iconPath) {
        # TODO: change taskbar icon?
        # WPF wants the absolute path
        $iconPath = (Resolve-Path $iconPath).Path
        $xaml = $xaml.Replace('INSERT_ICON_PATH',$iconPath)
    }
    else {
        # No icon specified
        $xaml = $xaml.Replace('Icon="INSERT_ICON_PATH" ','')
    }

    # Add CSV data to XAML
    # Row counter
    $script:row = 0
    # Not using Group-Object as PS7-preview4 does not preserve original order
    $sections = $csvData.Section | Where-Object {-not [string]::IsNullOrEmpty($_) } | Get-Unique
    # Generate GUI rows
    ForEach ($section in $sections) {
        Write-Verbose "Adding GUI Section: $section..."
        # Section Heading
        $xaml += New-GuiHeading $section
        $csvData | Where-Object {$_.Section -eq $section} | ForEach-Object {
            # Add items
            $xaml += New-GuiRow $_
        }
    }
    Write-Verbose 'Adding any items with blank Section...'
    $csvData | Where-Object { [string]::IsNullOrEmpty($_.Section) } | ForEach-Object {
        $xaml += New-GuiRow $_
        # TODO: spacing at top of window is untidy with no Sections (minor)
    }
    Write-Verbose "Added $($row) GUI rows"

    # Finish constructing XAML
    $xaml += Get-Content "$moduleRoot\xaml\end.xaml"

    Write-Verbose 'Creating XAML objects...'
    $form = New-GuiForm -inputXml $xaml

    Write-Verbose "Found $($buttons.Count) buttons"
    Write-Verbose 'Adding click actions...'
    ForEach ($button in $buttons) {
        $button.Add_Click( {
            # Use object in pipeline to identify script to run
            Invoke-ButtonAction $_.Source.Name
        } )
    }

    if ($hideConsole) {
        if ($global:error[0].Exception.CommandInvocation.MyCommand.ModuleName -ne 'PSScriptMenuGui') {
            # Do not hide console if there have been errors
            Hide-Console | Out-Null
        }
    }

    Write-Verbose 'Showing dialog...'
    $Form.ShowDialog() | Out-Null
}

Function New-ScriptMenuGuiExample {
    <#
    .SYNOPSIS
        Creates an example set of files for PSScriptMenuGui
    .PARAMETER path
        Path of output folder
    .EXAMPLE
        New-ScriptMenuGuiExample -path 'PSScriptMenuGui_example'
    .LINK
        https://github.com/weebsnore/PowerShell-Script-Menu-Gui
    #>
    [CmdletBinding()]
    param (
        [string]$path = 'PSScriptMenuGui_example'
    )

    # Ensure folder exists
    if (-not (Test-Path -Path $path -PathType Container) ) {
        New-Item -Path $path -ItemType 'directory' -Verbose | Out-Null
    }

    Write-Verbose "Copying example files to $path..." -Verbose
    Copy-Item -Path "$moduleRoot\examples\*" -Destination $path
}