PSScriptMenuGui
==

This is an early version. What do you think?

Feedback very welcome.

Compatibility
--
- Tested with **PowerShell 5.1 x64** and **PowerShell 7-preview 4 x64**.
- This module does not currently work with PowerShell 7-preview and the VS Code integrated console.

Try it out
--
    git clone https://github.com/weebsnore/PowerShell-Script-Menu-Gui
    cd PowerShell-Script-Menu-Gui/examples
    .\PSScriptMenuGui.ps1

![](demo.gif)

Basic usage
--

    Show-ScriptMenuGui -csvPath '.\example_data.csv'

See [`PSScriptMenuGui_all_options.ps1`](examples\PSScriptMenuGui_all_options.ps1) for more options.

CSV column reference
--

| |Section	| Method | Command | Name | Description
---|---|---|---|---|---
**What is it?** | Text for heading *(optional)* | One of: `cmd,powershell_file,powershell_inline,pwsh_file,pwsh_inline` | Path to target script or executable | Text for button | Text for description
**Example** | Old school | `cmd` | `example_target.cmd` | Example 1: cmd | .cmd file
**Example** | Old school | `cmd` | `taskmgr.exe` | Example 2: cmd | External executable
**Example** | Less old | `powershell_file` | `example_target.ps1` | Example 3: powershell_file | .ps1 file called with powershell.exe
**Example** | The future | `pwsh_file` | `example_target.ps1` | Example 5: pwsh_file | .ps1 file called with pwsh.exe

Notes:
- Relative paths and paths in your environment should work.
- `<LineBreak />` is supported in text fields.
- Excel makes a good editor!

See [example_data.csv](examples\example_data.csv) for more.