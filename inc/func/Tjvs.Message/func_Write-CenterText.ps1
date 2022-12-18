function Write-CenterText {
    <#
        .SYNOPSIS
            Displays a centred message on the screen
        .DESCRIPTION
            This function takes care of displaying a message by centring it on the screen.
            It is also possible to add it to a log.
        .PARAMETER sString
            Character string to be centred on the screen
        .PARAMETER sLogFile
            String indicating the location of the log file
        .EXAMPLE
            Write-CenterText "File Recovery..."
        .EXAMPLE
            Write-CenterText "Process not found" C:\Temp\restauration.log
        .NOTES
            Name           : Write-CenterText
            Created by     : Chucky2401
            Date created   : 01/01/2021
            Modified by    : Chucky2401
            Date modified  : 02/06/2022
            Change         : Translate to english
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position=0,Mandatory=$true)]
        [string]$sString,
        [Parameter(Position=1,Mandatory=$false)]
        [string]$sLogFile = $null
    )
    $nConsoleWidth    = (Get-Host).UI.RawUI.MaxWindowSize.Width
    $nStringLength    = $sString.Length
    $nPaddingSize     = "{0:N0}" -f (($nConsoleWidth - $nStringLength) / 2)
    $nSizePaddingLeft = $nPaddingSize / 1 + $nStringLength
    $sFinalString     = $sString.PadLeft($nSizePaddingLeft, " ").PadRight($nSizePaddingLeft, " ")

    Write-Host $sFinalString
    If ($null -ne $sLogFile) {
        Write-Output $sFinalString >> $sLogFile
    }
}
