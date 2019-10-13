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

    # Record -Verbose value, to pass to select cmdlets
    $verbose = $false
    try {
        if ($PSBoundParameters['Verbose'].ToString() -eq 'True') {
            $verbose = $true
        }
    }
    catch {}

    if ($hideConsole) {
        # TODO: This will also hide errors. Should be done later?
        Hide-Console | Out-Null
    }

    $csvData = Import-CSV $csvPath
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
        $iconPath = (Resolve-Path $iconPath).Path
        $xaml = $xaml.Replace('INSERT_ICON_PATH',$iconPath)
    }
    else {
        $xaml = $xaml.Replace('Icon="INSERT_ICON_PATH" ','')
    }

    # Row counter
    $script:row = 0
    # Add CSV data to XAML
    # Not using Group-Object as PS7-preview4 does not preserve original order
    $sections = $csvData.Section | Where-Object {-not [string]::IsNullOrEmpty($_)} | Get-Unique

    # Generate GUI rows
    ForEach ($section in $sections) {
        Write-Verbose "Adding GUI Section: $section  ..."
        # Section Heading
        $xaml += New-GuiHeading $section
        $csvData | Where-Object {$_.Section -eq $section} | ForEach-Object {
            # Add items
            $xaml += New-GuiRow $_
        }
    }
    Write-Verbose 'Adding any items with blank Section...'
    $csvData | Where-Object {[string]::IsNullOrEmpty($_.Section)} | ForEach-Object {
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

    Write-Verbose 'Showing dialog...'
    $Form.ShowDialog() | Out-Null
}