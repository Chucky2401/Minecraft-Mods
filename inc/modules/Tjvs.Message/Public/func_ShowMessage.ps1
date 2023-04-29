function ShowMessage {
    <#
        .SYNOPSIS
            Displays a message
        .DESCRIPTION
            This function displays a message with a different colour depending on the type of message.
            It also displays the date and time at the beginning of the line, followed by the message type in brackets.
        .PARAMETER type
            Type de message :
                INFO        : Informative message in blue
                WARNING     : Warning message in yellow
                ERROR       : Error message in red
                SUCCESS     : Success message in green
                DEBUG       : Debugging message in blue on black background
                OTHER       : Informative message in blue but without the date and type at the beginning of the line
        .PARAMETER message
            Message to be displayed
        .EXAMPLE
            ShowLogMessage "INFO" "File recovery..."
        .EXAMPLE
            ShowLogMessage "WARNING" "Process not found"
        .NOTES
            Name           : ShowMessage
            Created by     : Chucky2401
            Date created   : 01/01/2019
            Modified by    : Chucky2401
            Date modified  : 07/04/2021
            Change         : Translate to english
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
        [Parameter(Mandatory = $False)]
        [AllowEmptyString()]
        [Alias("v")]
        [string[]]$variable
    )

    If ($variable.count -ge 1) {
        $message = $message -f $variable
    }

    $sDate = Get-Date -UFormat "%d.%m.%Y - %H:%M:%S"

    switch ($type) {
        "INFO" {
            Write-Host "[$($sDate)] (INFO)    $($message)" -ForegroundColor Cyan
            Break
        }
        "WARNING" {
            Write-Host "[$($sDate)] (WARNING) $($message)" -ForegroundColor DarkYellow -BackgroundColor Black
            Break
        }
        "ERROR" {
            Write-Host "[$($sDate)] (ERROR)   $($message)" -ForegroundColor Red
            Break
        }
        "SUCCESS" {
            Write-Host "[$($sDate)] (SUCCESS) $($message)" -ForegroundColor Green
            Break
        }
        "DEBUG" {
            If ($DebugPreference -eq "Continue" -or $PSBoundParameters['Debug']) {
                Write-Host "[$($sDate)] (DEBUG)   $($message)" -ForegroundColor White -BackgroundColor Black
            }
            Break
        }
        "OTHER" {
            Write-Host "$($message)"
            Break
        }
        default {
            Write-Host "[$($sDate)] (INFO)    $($message)" -ForegroundColor Cyan
        }
    }
}
