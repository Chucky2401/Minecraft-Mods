function Get-Settings {
    <#
        .SYNOPSIS
            Get settings from ini file
        .DESCRIPTION
            Return as a hashtable the settings from an ini file
        .PARAMETER File
            Path of the settings file
        .OUTPUTS
            Settings as a hashtable
        .EXAMPLE
            Get-Settings "$($PSScriptRoot)\conf\settings.ini"
        .NOTES
            Name           : Get-Settings
            Created by     : Chucky2401
            Date created   : 08/07/2022
            Modified by    : Chucky2401
            Date modified  : 21/08/2022
            Change         : Manage a starting and ending position in the settings
        .LINK
            http://git.sterimed.local/-/snippets/10
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $False)]
        [string]$File = ".\conf\settings.json"
    )

    $oSettings = Get-Content $File | ConvertFrom-Json

    $bValidSettings = Test-Settings -Settings $oSettings

    If (-not $bValidSettings) {
        Throw "Settings invalid!"
    }

    Return $oSettings
}
