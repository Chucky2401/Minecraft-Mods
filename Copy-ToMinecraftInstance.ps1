<#
    .SYNOPSIS
        Summary of the script
    .DESCRIPTION
        Script description
    .PARAMETER param1
        Parameter description
    .INPUTS
        Pipeline input data
    .OUTPUTS
        Output data
    .EXAMPLE
        .\template.ps1 param1
    .NOTES
        Name           : Script-Name
        Version        : 1.0.0
        Created by     : Chucky2401
        Date Created   : 14/08/2022
        Modify by      : Chucky2401
        Date modified  : 14/08/2022
        Change         : Creation
        Copy           : Copy-Item .\Script-Name.ps1 \Final\Path\Script-Name.ps1 -Force
    .LINK
        http://github.com/UserName/RepoName
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
Param (
    [Parameter(ValueFromPipeline)]
    [Object[]]$Mods                                                                                                     # Mettre sous forme d'array pour l'appel sans Pipeline
)

BEGIN {
    #---------------------------------------------------------[Initialisations]--------------------------------------------------------

    #Set Error Action to Silently Continue
    $ErrorActionPreference      = "SilentlyContinue"
    If ($PSBoundParameters['Debug']) {
        $DebugPreference = "Continue"
    } Else {
        $DebugPreference = "SilentlyContinue"
    }

    #-----------------------------------------------------------[Functions]------------------------------------------------------------

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

        If ($bNoDebug -or (-not $bNoDebug -and ($PSBoundParameters['Debug'] -or $DebugPreference -eq "Continue"))) {
            If ($sLogFile.Value.GetType().Name -ne "String") {
                $sLogFile.Value += $sSortie
            }
            Else {
                Write-Output $sSortie >> $sLogFile.Value
            }
        }
    }

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
                Date modified  : 10/08/2021
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
            [string]$message
        )

        $sDate = Get-Date -UFormat "%d.%m.%Y - %H:%M:%S"

        switch ($type) {
            "INFO" {
                Write-Host "[$($sDate)] (INFO)    $($message)" -ForegroundColor Cyan
                Break
            }
            "WARNING" {
                Write-Host "[$($sDate)] (WARNING) $($message)" -ForegroundColor Yellow -BackgroundColor Black
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
        $bNoDebug = $True

        Switch ($type) {
            "INFO" {
                $sSortie = "[$($sDate)] (INFO)    $($message)"
                Write-Host $sSortie -ForegroundColor Cyan
                Break
            }
            "WARNING" {
                $sSortie = "[$($sDate)] (WARNING) $($message)"
                Write-Host $sSortie -ForegroundColor White -BackgroundColor Black
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
                $bNoDebug = $False
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

        If ($bNoDebug -or (-not $bNoDebug -and ($PSBoundParameters['Debug'] -or $DebugPreference -eq "Continue"))) {
            If ($sLogFile.Value.GetType().Name -ne "String") {
                $sLogFile.Value += $sSortie
            }
            Else {
                Write-Output $sSortie >> $sLogFile.Value
            }
        }
    }

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

    #----------------------------------------------------------[Declarations]----------------------------------------------------------

    $counter = 1

    #-----------------------------------------------------------[Execution]------------------------------------------------------------
}

PROCESS {
    foreach ($mod in $Mods) {                                                                                           # Obligatoire si non utilisation du Pipeline + Array
        Write-Host "$($counter): $($mod.Name) - $($mod.FileName)"
        $counter++
    }
}
