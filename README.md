PSScriptMenuGui
==

Do you have favourite scripts that go forgotten?

Does your organisation have scripts that would be useful to frontline staff who are not comfortable with the command line?

This module uses a CSV file to make a graphical menu of PowerShell scripts.

It's easy to customise and fast to launch.

You can also add Windows programs and files to the menu.

Just a few minutes to setup and - *click! click!* - you're away!

This an early version. What do you think? What's missing?

Feedback very welcome.

[@dan_osull.com](https://twitter.com/dan_osull_com/)  
https://blog.osull.com  
powershell@osull.com

Compatibility
--
- Tested with **PowerShell 5.1 x64** and **PowerShell 7-preview 4 x64** on Windows 10.
- This module does not currently work with PowerShell 7-preview in the VS Code integrated console.

Try it out
--
    git clone https://github.com/weebsnore/PowerShell-Script-Menu-Gui
    cd PowerShell-Script-Menu-Gui/examples
    .\PSScriptMenuGui.ps1

Or - if you don't have Git - [download the project ZIP](https://github.com/weebsnore/PowerShell-Script-Menu-Gui/archive/master.zip), unzip somewhere convenient, and experiment with editing [`examples\example_data.csv`](examples/example_data.csv) and running [`examples\PSScriptMenuGui.ps1`](examples/PSScriptMenuGui.ps1)

When the module is a bit more mature I'll put it in the PowerShell Gallery so it can be installed with `Install-Module`

![](demo.gif)

Basic usage
--

    Show-ScriptMenuGui -csvPath '.\example_data.csv'

See [`PSScriptMenuGui_all_options.ps1`](examples/PSScriptMenuGui_all_options.ps1) for an example with all options.

CSV column reference
--
...and selected examples

| |Section	| Method | Command | Arguments | Name | Description
---|---|---|---|---|---|---
**What is it?** | Text for heading *(optional)* | What happens when you click the button? Valid options: `cmd` \| `powershell_file` \| `powershell_inline` \| `pwsh_file` \| `pwsh_inline` | Path to target script/executable (`cmd` or `_file` methods) ***or*** PowerShell commands (`_inline` methods) | Arguments to pass to target executable (`cmd` method) ***or*** to the PowerShell exe *(optional)* | Text for button | Text for description *(optional)*
**Example** | Old school | `cmd` | `example_target.cmd` | | Example 1: cmd | .cmd file
**Example** | Old school | `cmd` | `taskmgr.exe` | | Example 2: cmd | External executable
**Example** | Old school | `cmd` | `notepad.exe` | `hello` | Example 3: cmd | External executable with arguments
**Example** | Less old | `powershell_file` | `example_target.ps1` | | Example 4: powershell_file | .ps1 file called with powershell.exe
**Example** | Less old | `powershell_inline` | `$PSVersionTable` | `-NoExit -WindowStyle Maximized` | Example 6: powershell_file | Additional powershell.exe arguments
**Example** | The future | `pwsh_file` | `example_target.ps1` | | Example 7: pwsh_file | .ps1 file called with pwsh.exe
**Example** | The future | `pwsh_inline` | `& .\example_target.ps1 -Message "passed in via param"` | |Example 9: pwsh_inline | .ps1 file called with parameter

Tips:
- Relative paths, network paths and paths in your environment should work.
- `<LineBreak />` is supported in text fields.
- You can add multiple `_inline` commands by separating with a semi-colon (`;`).
- Excel makes a good editor!
- But watch out for Excel turning e.g. `-NoExit` into a formula. Best workaround is to prefix with a space.

See [example_data.csv](examples/example_data.csv) for further examples.

![](excel.png)

Known issues
--
- Various minor issues - see `TODO:` comments in code.
