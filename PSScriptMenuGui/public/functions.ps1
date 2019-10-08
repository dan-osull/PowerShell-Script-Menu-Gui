Function Show-ScriptMenuGui {
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

    if ($hideConsole) {
        # TODO: This will also hide errors. Should be done later?
        Hide-Console | Out-Null
    }

    $csvData = Import-CSV $csvPath
    # TODO: validate CSV input

    # Add unique Reference to each item
    # Used as x:Name of button and to look up action on click
    $i = 0
    $csvData | ForEach-Object {
        $_ | Add-Member -Name Reference -MemberType NoteProperty -Value "button$i"
        $i++
    }

    # Begin constructing XAML
    $xaml = @()
    $xaml += Get-Content "$moduleRoot\xaml\start.xaml"
    $xaml = $xaml.Replace('INSERT_WINDOW_TITLE',$windowTitle)
    if ($iconPath) {
        # TODO: change taskbar icon?
        $iconPath = (Resolve-Path $iconPath).Path
        $xaml = $xaml.Replace('INSERT_ICON_PATH',$iconPath)
    }
    else {
        $xaml = $xaml.Replace('Icon="INSERT_ICON_PATH" ','')
    }

    # Row counter
    $script:row = 0
    # Add CSV data to XAML
    $sections = $csvData | Group-Object -Property Section
    # TODO: section order is not preserved in PS7
    if ($sections.Name) {
        # Section column is present
        ForEach ($section in $sections) {
            $xaml += New-GuiHeading $section.Values
            ForEach ($item in $section.Group) {
                # TODO: error if individual item is missing Section
                $xaml += New-GuiRow $item
            }
        }
    }
    else {
        # Section column is not present
        # TODO: tidy up spacing at top (minor)
        ForEach ($item in $csvData) {
            $xaml += New-GuiRow $item
        }
    }

    # Finish constructing XAML
    $xaml += Get-Content "$moduleRoot\xaml\end.xaml"

    # Generate form
    $form = New-GuiForm -inputXml $xaml

    # Add clicks to buttons
    ForEach ($buttonVariable in Get-Variable WPF_button*) {
        $buttonVariable.Value.Add_Click( {
            # Use object in pipeline to identify script to run
            Start-Script $_.Source.Name
        } )
    }

    # Show form
    $Form.ShowDialog() | Out-Null
}