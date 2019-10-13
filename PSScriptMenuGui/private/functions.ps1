function Hide-Console {
    # https://stackoverflow.com/questions/40617800/opening-powershell-script-and-hide-command-prompt-but-not-the-gui
    # .NET methods for hiding/showing the console in the background
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
        # TODO: Window MinWidth is too high if no items have Description
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
    # Preserves line breaks. A bit hacky. Bad idea?
    # https://stackoverflow.com/questions/183406/newline-in-string-attribute
    # TODO: <Paragraph> support?
    $string = $string.Replace('&lt;LineBreak /&gt;','<LineBreak />')

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

    #region Load XAML objects in PowerShell
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
        try {
            # TODO: could put these in a hashtable instead
            Set-Variable -Name "WPF_$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop -Scope script
        }
        catch {
            throw
        }
    }

    return $form
}

Function Start-Script {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$buttonName
    )
    Write-Verbose "$buttonName clicked"
    # Get relevant CSV row
    $csvMatch = $csvData | Where-Object {$_.Reference -eq $buttonName}
    Write-Verbose $csvMatch
    # TODO: pass $csvMatch to second Function and validate parameters?

    # Get Command
    $command = $csvMatch.Command
    $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))

    # TODO: check that target file exist?

    # Handle cmd first
    if ($csvMatch.Method -eq 'cmd') {
        if ($csvMatch.Arguments) {
            # Using .NET, as Start-Process adds a trailing space to arguments
            # https://social.technet.microsoft.com/Forums/en-US/97be1de5-f31e-416e-9752-ed60c39c0383/powershell-40-startprocess-adds-extra-space-to-commandline
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo.FileName = $command
            $process.StartInfo.Arguments = $csvMatch.Arguments
            $process.Start()
        }
        else {
            Start-Process -FilePath $command -Verbose:$verbose
        }
        return
    }

    # Begin constructing PowerShell arguments
    $arguments = @()
    $arguments += '-ExecutionPolicy Bypass'
    $arguments += '-NoLogo'
    if ($noExit) {
        # Global -NoExit switch
        $arguments += '-NoExit'
    }
    if ($csvMatch.Arguments) {
        # Additional arguments from CSV
        $arguments += $csvMatch.Arguments
    }

    # Set Start-Process params according to CSV method
    $method = $csvMatch.Method.Split('_')
    switch ($method[0]) {
        powershell {
            $filePath = 'powershell.exe'
        }
        pwsh {
            $filePath = 'pwsh.exe'
        }
    }
    switch ($method[1]) {
        file {
            $arguments += "-File `"$command`""
        }
        inline {
            $arguments += "-EncodedCommand `"$encodedCommand`""
        }
    }

    # Launch process
    $arguments | ForEach-Object {Write-Verbose $_}
    Start-Process -FilePath $filePath -ArgumentList $arguments -Verbose:$verbose
}