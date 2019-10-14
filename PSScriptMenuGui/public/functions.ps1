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
        $iconPath = (Resolve-Path $iconPath).Path
        # WPF wants the absolute path
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
    [CmdletBinding()]
    param (
        $path = '.'
    )

    # Ensure folder exists
    if (-not (Test-Path -Path $path -PathType Container) ) {
        Write-Verbose "Creating directory $path..."
        New-Item -Path $path -ItemType 'directory' | Out-Null
    }

    Write-Verbose "Copying examples to $path..."
    Copy-Item -Path "$moduleRoot\examples\*" -Destination $path
}