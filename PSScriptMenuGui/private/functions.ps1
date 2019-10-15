function Hide-Console {
    Write-Verbose 'Hiding PowerShell console...'
    # .NET method for hiding the PowerShell console window
    # https://stackoverflow.com/questions/40617800/opening-powershell-script-and-hide-command-prompt-but-not-the-gui
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    '
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 0) # 0 = hide
}

Function New-GuiHeading {
    param(
        [Parameter(Mandatory)][string]$name
    )
    $string = Get-Content "$moduleRoot\xaml\heading.xaml"
    $string = $string.Replace('INSERT_SECTION_HEADING',(Get-XamlSafeString $name) )
    $string = $string.Replace('INSERT_ROW',$row)
    $script:row++

    return $string
}

Function New-GuiRow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][PSCustomObject]$item
    )
    Write-Verbose $item

    $string = Get-Content "$moduleRoot\xaml\item.xaml"
    $string = $string.Replace('INSERT_BACKGROUND_COLOR',$buttonBackgroundColor)
    $string = $string.Replace('INSERT_FOREGROUND_COLOR',$buttonForegroundColor)
    $string = $string.Replace('INSERT_BUTTON_TEXT',(Get-XamlSafeString $item.Name) )
    # Description is optional
    if ($item.Description) {
        $string = $string.Replace('INSERT_DESCRIPTION',(Get-XamlSafeString $item.Description) )
    }
    else {
        $string = $string.Replace('INSERT_DESCRIPTION','')
    }
    $string = $string.Replace('INSERT_BUTTON_NAME',$item.Reference)
    $string = $string.Replace('INSERT_ROW',$row)
    $script:row++

    return $string
}

Function Get-XamlSafeString {
    param(
        [Parameter(Mandatory)][string]$string
    )
    # https://docs.microsoft.com/en-us/dotnet/framework/wpf/advanced/how-to-use-special-characters-in-xaml
    # Order matters: &amp first
    $string = $string.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
    # Restore line breaks
    $string = $string -replace '&lt;\s*?LineBreak\s*?\/\s*?&gt;','<LineBreak />'

    return $string
}

Function New-GuiForm {
    # Based on: https://foxdeploy.com/2015/05/14/part-iii-using-advanced-gui-elements-in-powershell/
    param (
        [Parameter(Mandatory)][array]$inputXml # XML has not been converted to object yet
    )
    # Process raw XML
    $inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*','<Window'

    # Read XAML
    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    [xml]$xaml = $inputXML
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    try {
        $form = [Windows.Markup.XamlReader]::Load($reader)
    }
    catch {
        Write-Warning "Unable to parse XML!
Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them).
Note that this module does not currently work with PowerShell 7-preview and the VS Code integrated console."
        throw
    }

    # Load XAML button objects in PowerShell
    $script:buttons = @()
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
        try {
            $script:buttons += $Form.FindName($_.Name)
        }
        catch {
            throw
        }
    }

    return $form
}

Function Invoke-ButtonAction {
    param(
        [Parameter(Mandatory)][string]$buttonName
    )
    Write-Verbose "$buttonName clicked"

    # Get relevant CSV row
    $csvMatch = $csvData | Where-Object {$_.Reference -eq $buttonName}
    Write-Verbose $csvMatch

    # Pipe match to Start-Script function
    # Lets us check CSV data via parameter validation
    try {
        $csvMatch | Start-Script -ErrorAction Stop
    }
    catch {
        Write-Error $_
    }
}

Function Start-Script {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateSet('cmd','powershell_file','powershell_inline','pwsh_file','pwsh_inline')]
        [string]$method,

        [Parameter(Mandatory,ValueFromPipelineByPropertyName)][string]$command,

        [Parameter(ValueFromPipelineByPropertyName)][string]$arguments
    )

    # Handle cmd first
    if ($method -eq 'cmd') {
        if ($arguments) {
            # Using .NET directly, as Start-Process adds a trailing space to arguments
            # https://social.technet.microsoft.com/Forums/en-US/97be1de5-f31e-416e-9752-ed60c39c0383/powershell-40-startprocess-adds-extra-space-to-commandline
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo.FileName = $command
            $process.StartInfo.Arguments = $arguments
            # Set process working directory to PowerShell working directory
            # Mimics behaviour of exe called from cmd prompt
            $process.StartInfo.WorkingDirectory = $PWD
            $process.Start()
        }
        else {
            Start-Process -FilePath $command -Verbose:$verbose
        }
        return
    }

    # Begin constructing PowerShell arguments
    $psArguments = @()
    $psArguments += '-ExecutionPolicy Bypass'
    $psArguments += '-NoLogo'
    if ($noExit) {
        # Global -NoExit switch
        $psArguments += '-NoExit'
    }
    if ($arguments) {
        # Additional PS arguments from CSV
        # PowerShell doesn't seem to care if it gets the same argument twice
        $psArguments += $arguments
    }

    # Set Start-Process params according to CSV method
    $splitMethod = $method.Split('_')
    $encodedCommand = [Convert]::ToBase64String( [System.Text.Encoding]::Unicode.GetBytes($command) )
    switch ($splitMethod[0]) {
        powershell {
            $filePath = 'powershell.exe'
        }
        pwsh {
            $filePath = 'pwsh.exe'
        }
    }
    switch ($splitMethod[1]) {
        file {
            $psArguments += "-File `"$command`""
        }
        inline {
            $psArguments += "-EncodedCommand `"$encodedCommand`""
        }
    }

    # Launch process
    $psArguments | ForEach-Object { Write-Verbose $_ }
    Start-Process -FilePath $filePath -ArgumentList $psArguments -Verbose:$verbose
}