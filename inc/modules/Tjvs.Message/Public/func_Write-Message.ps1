function Write-Message {
    <#
        .SYNOPSIS
            Displays a message
        .DESCRIPTION
            This function displays a message with a different colour depending on the type of message, and let you log it to a file.
            It also displays the date and time at the beginning of the line, followed by the type of message in brackets.
        .PARAMETER Type
            Type de message :
                INFO    : Informative message in blue
                WARNING : Warning message in yellow
                ERROR   : Error message in red
                SUCCESS : Success message in green
                DEBUG   : Debugging message in blue on black background
                OTHER   : Informative message in blue but without the date and type at the beginning of the line
        .PARAMETER Message
            Message to be displayed
        .PARAMETER LogFile
            String or variable reference indicating the location of the log file.
            It is possible to send a variable of type Array() so that the function returns the string. See Example 3 for usage in this case.
        .EXAMPLE
            Write-Message "INFO" "File recovery..." ([ref]"C:\Temp\trace.log")

            Show to the console "[19/04/2023 - 10:35:46] (INFO)    File recovery..."
        .EXAMPLE
            Write-Message "WARNING" "Process not found" -Logging -LogFile ([ref]"C:\Temp\trace.log")

            Show to the console "[19/04/2023 - 10:35:46] (WARNING) Process not found" and write it to the file 'C:\Temp\trace.log'
        .EXAMPLE
            $bufferLog = @()
            Write-Message "WARNING" "Processus introuvable" ([ref]bufferLog)

            Show to the console "[19/04/2023 - 10:35:46] (WARNING) Processus introuvable" and store it to the array $bufferLog
        .NOTES
            Name           : Write-Message
            Created by     : Tristan BR�JON
            Date created   : 18/04/2023
            Modified by    : Tristan BR�JON
            Date modified  : 18/04/2023
            Change         : Creation
    #>

    [CmdletBinding(DefaultParameterSetName = "Show")]
    Param (
        [Parameter(Mandatory = $True, ParameterSetName = "Show", Position = 0)]
        [Parameter(Mandatory = $True, ParameterSetName = "Log", Position = 0)]
        [Alias("t")]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "DEBUG", "OTHER", IgnoreCase = $False)]
        [string]$Type,
        [Parameter(Mandatory = $True, ParameterSetName = "Show", Position = 1)]
        [Parameter(Mandatory = $True, ParameterSetName = "Log", Position = 1)]
        [AllowEmptyString()]
        [Alias("m")]
        [string]$Message,
        [Parameter(Mandatory = $False, ParameterSetName = "Show", Position = 1)]
        [Parameter(Mandatory = $False, ParameterSetName = "Log", Position = 1)]
        [AllowEmptyString()]
        [Alias("v")]
        [string[]]$Variables,
        [Parameter(Mandatory = $True, ParameterSetName = "Log", Position = 2)]
        [Alias("f")]
        [ref]$LogFile
    )

    If (-not [String]::IsNullOrEmpty($LogFile)) {
        $Logging = $True
        $typeLogFile = $LogFile.Value.GetType().Name
    }

    If ($Variables.count -ge 1) {
        $Message = $Message -f $Variables
    }
    
    $dateNow = Get-Date -UFormat "%d.%m.%Y - %H:%M:%S"

    Switch ($type) {
        "INFO" {
            $outString = "[$($dateNow)] (INFO)    $($message)"
            Write-Host $outString -ForegroundColor Cyan
            Break
        }
        "WARNING" {
            $outString = "[$($dateNow)] (WARNING) $($message)"
            Write-Host $outString -ForegroundColor DarkYellow -BackgroundColor Black
            Break
        }
        "ERROR" {
            $outString = "[$($dateNow)] (ERROR)   $($message)"
            Write-Host $outString -ForegroundColor Red
            Break
        }
        "SUCCESS" {
            $outString = "[$($dateNow)] (SUCCESS) $($message)"
            Write-Host $outString -ForegroundColor Green
            Break
        }
        "DEBUG" {
            $outString = "[$($dateNow)] (DEBUG)   $($message)"
            If ($DebugPreference -eq "Continue" -or $PSBoundParameters['Debug']) {
                Write-Host $outString -ForegroundColor White -BackgroundColor Black
            }
            Break
        }
        "OTHER" {
            $outString = "$($message)"
            Write-Host $outString
            Break
        }
    }

    If (-not $Logging) {
        Return
    }

    If ($Type -eq "DEBUG" -and (-not $PSBoundParameters['Debug'] -and $DebugPreference -ne "Continue")) {
        Return
    }

    If ($typeLogFile -ne "String") {
        $LogFile.Value += $outString
    }
    
    If ($typeLogFile -eq "String") {
        Write-Output $outString | Out-File $LogFile.Value -Encoding utf8 -Append
    }
}
