function ShowLogMessage {
    <#
        .SYNOPSIS
            Displays a message and adds it to a log file
        .DESCRIPTION
            This function displays a message with a different colour depending on the type of message, and logs the same message to a log file.
            It also displays the date and time at the beginning of the line, followed by the type of message in brackets.
        .PARAMETER type
            Type de message :
                INFO    : Informative message in blue
                WARNING : Warning message in yellow
                ERROR   : Error message in red
                SUCCESS : Success message in green
                DEBUG   : Debugging message in blue on black background
                OTHER   : Informative message in blue but without the date and type at the beginning of the line
        .PARAMETER message
            Message to be displayed
        .PARAMETER sLogFile
            String or variable reference indicating the location of the log file.
            It is possible to send a variable of type Array() so that the function returns the string. See Example 3 for usage in this case.
        .EXAMPLE
            ShowLogMessage "INFO" "File recovery..." ([ref]sLogFile)
        .EXAMPLE
            ShowLogMessage "WARNING" "Process not found" ([ref]sLogFile)
        .EXAMPLE
            aTexte = @()
            ShowLogMessage "WARNING" "Processus introuvable" ([ref]aTexte)
        .NOTES
            Name           : ShowLogMessage
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
            Write-Host $sSortie -ForegroundColor Cyan
            Break
        }
        "WARNING" {
            $sSortie = "[$($sDate)] (WARNING) $($message)"
            Write-Host $sSortie -ForegroundColor DarkYellow -BackgroundColor Black
            Break
        }
        "ERROR" {
            $sSortie = "[$($sDate)] (ERROR)   $($message)"
            Write-Host $sSortie -ForegroundColor Red
            Break
        }
        "SUCCESS" {
            $sSortie = "[$($sDate)] (SUCCESS) $($message)"
            Write-Host $sSortie -ForegroundColor Green
            Break
        }
        "DEBUG" {
            $sSortie = "[$($sDate)] (DEBUG)   $($message)"
            If ($DebugPreference -eq "Continue" -or $PSBoundParameters['Debug']) {
                Write-Host $sSortie -ForegroundColor White -BackgroundColor Black
            }
            Break
        }
        "OTHER" {
            $sSortie = "$($message)"
            Write-Host $sSortie
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
