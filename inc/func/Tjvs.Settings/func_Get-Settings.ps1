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
        [Parameter(Position = 0, Mandatory = $True)]
        [string]$File,
        [Parameter(Position = 1, Mandatory = $False)]
        [string]$StartBlock = "",
        [Parameter(Position = 2, Mandatory = $False)]
        [string]$EndBlock = ""
    )

    $htSettings = @{}
    If ($StartBlock -eq "") {
        $bReadSettings = $True
    } Else {
        $bReadSettings = $False
    }

    Get-Content $File | ForEach-Object {
        If ($PSItem -match "^;|^\[" -or $PSItem -eq "") {
            If ($StartBlock -ne "" -and $PSItem -match $StartBlock) {
                $bReadSettings = $True
            }
            If ($EndBlock -ne "" -and $PSItem -match $EndBlock) {
                $bReadSettings = $False
            }
            
            return
        }

        If ($bReadSettings) {
            $aLine = [regex]::Split($PSItem, '=')
            If ($aLine[1].Trim() -match "^`".+`"$") {
                [String]$value = $aLine[1].Trim() -replace "^`"(.+)`"$", "`$1"
            }
            Else {
                [Int32]$value = $aLine[1].Trim()
            }
            $htSettings.Add($aLine[0].Trim(), $value)
        }
    }

    Return $htSettings
}
