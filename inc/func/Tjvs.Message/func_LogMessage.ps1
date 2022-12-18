function LogMessage {
    <#
        .SYNOPSIS
            Adds a message to a log file
        .DESCRIPTION
            This function adds a message to a log file.
            It also displays the date and time at the beginning of the line, followed by the message type in brackets.
        .PARAMETER type
            Type de message :
                INFO        : Informative message
                WARNING     : Warning message
                ERROR       : Error message
                SUCCESS     : Success message
                DEBUG       : Debugging message
                OTHER       : Informative message but without the date and type at the beginning of the line
        .PARAMETER message
            Message to be logged
        .PARAMETER sLogFile
            String or variable reference indicating the location of the log file.
            It is possible to send a variable of type Array() so that the function returns the string. See Example 3 for usage in this case.
        .EXAMPLE
            LogMessage "INFO" "File recovery..." ([ref]sLogFile)
        .EXAMPLE
            LogMessage "WARNING" "Process not found" ([ref]sLogFile)
        .EXAMPLE
            aTexte = @()
            LogMessage "WARNING" "Process not found" ([ref]aTexte)
        .NOTES
            Name           : LogMessage
            Created by     : Chucky2401
            Date created   : 01/01/2019
            Modified by    : Chucky2401
            Date modified  : 10/08/2022
            Change         : For 'DEBUG' case show the message if -Debug parameter is used
    #>
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [Alias("t")]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG", "OTHER", IgnoreCase = $false)]
        [string]$type,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [Alias("m")]
        [string]$message,
        [Parameter(Mandatory = $true)]
        [Alias("l")]
        [ref]$sLogFile
    )

    $sDate = Get-Date -UFormat "%d.%m.%Y - %H:%M:%S"

    Switch ($type) {
        "INFO" {
            $sSortie = "[$($sDate)] (INFO)    $($message)"
            Break
        }
        "WARNING" {
            $sSortie = "[$($sDate)] (WARNING) $($message)"
            Break
        }
        "ERROR" {
            $sSortie = "[$($sDate)] (ERROR)   $($message)"
            Break
        }
        "SUCCESS" {
            $sSortie = "[$($sDate)] (SUCCESS) $($message)"
            Break
        }
        "DEBUG" {
            $sSortie = "[$($sDate)] (DEBUG)   $($message)"
            Break
        }
        "OTHER" {
            $sSortie = "$($message)"
            Break
        }
    }

    If ($type -ne "DEBUG" -or ($type -eq "DEBUG" -and ($PSBoundParameters['Debug'] -or $DebugPreference -eq "Continue"))) {
        If ($sLogFile.Value.GetType().Name -ne "String") {
            $sLogFile.Value += $sSortie
        } Else {
            Write-Output $sSortie >> $sLogFile.Value
        }
    }
}
