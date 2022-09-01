<#
    .SYNOPSIS
        Copy mods to Minecraft Instance
    .DESCRIPTION
        Get all updated mods from `Get-ModsNewVersion.ps1` and copy them to the folder instance of your Minecraft.
        You can alse use the exported csv file of mods to copy them.
    .PARAMETER Mods
        Array of updated mods
    .PARAMETER FromFile
        Switch to force using a csv file. The script will ask you to choose a file
    .PARAMETER CsvFile
        If you prefer to indicate the path to the csv file directly in command line
    .PARAMETER InstancePath
        Precise directly the folder to the Minecraft Instance (this folder must contains `mods`, `ressourcepacks` and `shaderpacks` folders)
    .PARAMETER InternalCategoryExclude
        Array of string to exclude one or more InternalCategory
    .PARAMETER GoCOnly
        Switch that copy only mods with the field GOC equal to True
    .PARAMETER Update
        Boolean. If set to false (default) the mods folder is emptying.
    .PARAMETER LogFile
        Use only with the first parameter (Mods).
        To log copy to the same log file as `Get-ModsNewVersion.ps1`
    .INPUTS
        Mods[]
    .EXAMPLE
        $Mods | Copy-ToMinecraftInstance.ps1 -InstancePath $env:APPDATA\.minecraft

        Copy all updated mods to the default instance of Minecraft
    .EXAMPLE
        $Mods | Copy-ToMinecraftInstance.ps1 -InstancePath $env:APPDATA\.minecraft -InternalCategoryExclude "Optifine"

        Copy all updated mods except one in the internal category Optifine to the default instance of Minecraft
    .EXAMPLE
        Copy-ToMinecraftInstance.ps1 -Mods $Mods -InstancePath $env:APPDATA\.minecraft -InternalCategoryExclude "Optifine","NoOptifine"

        Copy all updated mods except one in the internal category Optifine or NoOptifine to the default instance of Minecraft
    .EXAMPLE
        Copy-ToMinecraftInstance.ps1 -CsvFile "E:\Games\Minecraft\#Setup_Minecraft\#Scripts\Minecraft-Mods\csv\MC_1.19.0-2022.08.13_18.56.csv" -InstancePath "E:\Games\Minecraft\#MultiMC\instances\1.19-Opti\.minecraft" -InternalCategoryExclude "NoOptifine" -GoCOnly

        Copy all updated mods from the .csv file, in the specific instance path, where the internal category is not NoOptifine and where the field GOC is equal to True
    .NOTES
        Name           : Copy-ToMinecraftInstance
        Version        : 1.0.0.beta.2
        Created by     : Chucky2401
        Date Created   : 14/08/2022
        Modify by      : Chucky2401
        Date modified  : 01/09/2022
        Change         : Add -Update parameter
    .LINK
        https://github.com/Chucky2401/Minecraft-Mods/blob/main/README.md#copy-tominecraftinstance
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low", DefaultParameterSetName = "Pipeline")]
Param (
    [Parameter(ValueFromPipeline, ParameterSetName = "Pipeline", Mandatory)]
    [Object[]]$Mods,
    [Parameter(ParameterSetName = "File")]
    [Switch]$FromFile,
    [Parameter(ParameterSetName = "File")]
    [String]$CsvFile = "",
    [Parameter(ParameterSetName = "Pipeline")]
    [Parameter(ParameterSetName = "File")]
    [String]$InstancePath = "",
    [Parameter(ParameterSetName = "Pipeline")]
    [Parameter(ParameterSetName = "File")]
    [String[]]$InternalCategoryExclude,
    [Parameter(ParameterSetName = "Pipeline")]
    [Parameter(ParameterSetName = "File")]
    [Switch]$GoCOnly,
    [Parameter(ParameterSetName = "Pipeline")]
    [Parameter(ParameterSetName = "File")]
    [Boolean]$Update = $False,
    [Parameter(ParameterSetName = "Pipeline")]
    [String]$LogFile = ""
)

BEGIN {
    #---------------------------------------------------------[Initialisations]--------------------------------------------------------

    #Set Error Action to Silently Continue
    #$ErrorActionPreference      = "SilentlyContinue"
    $ErrorActionPreference      = "Stop"
    If ($PSBoundParameters['Debug']) {
        $DebugPreference = "Continue"
    } Else {
        $DebugPreference = "SilentlyContinue"
    }

    Add-Type -AssemblyName System.Windows.Forms

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
            } Else {
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

    #----------------------------------------------------------[Declarations]----------------------------------------------------------

    $htSettings = Get-Settings "$($PSScriptRoot)\conf\settings.ini" -StartBlock "Copy"

    # To don't change anything to my snippets! ;-)
    $sLogFile = $LogFile

    [ScriptBlock]$sbFilter = {[System.Convert]::ToBoolean($PSItem.Update)}

    If ($GoCOnly) {
        [ScriptBlock]$sbFilter = [ScriptBlock]::Create("$($sbFilter.ToString()) -and `$PSItem.GoC -eq `$True")
    }

    #-----------------------------------------------------------[Execution]------------------------------------------------------------

    If ($InstancePath -eq "") {
        $oFolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
            InitialDirectory = "$($htSettings['InitialDirectory'])"
            Description = "Select the instance folder only! Not mods or others subfolders!"
        }
        $null = $oFolderBrowser.ShowDialog()
        $InstancePath = $oFolderBrowser.SelectedPath
    }

    $sInstanceModsPath       = "$($InstancePath)\mods"
    $sInstanceRessourcesPath = "$($InstancePath)\resourcepacks"
    $sInstanceShadersPath    = "$($InstancePath)\shaderpacks"

    If ($PSCmdlet.ParameterSetName -eq "File" -and $CsvFile -eq "") {
        $oFileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
            InitialDirectory = "$($PSScriptRoot)"
            Title = "Choose CSV file containing mods update information..."
            Filter = "CSV files (*.csv)|*.csv"
        }
        $null = $oFileBrowser.ShowDialog()
        $CsvFile = $oFileBrowser.FileName
        $Mods = Import-Csv -Path $CsvFile -Delimiter ";" -Encoding UTF8
    }


    If ($InternalCategoryExclude.Count -ge 1) {
        $sFilterInternalCategory = "\b$([String]::Join("\b|\b", $InternalCategoryExclude))\b"
        [ScriptBlock]$sbFilter = [ScriptBlock]::Create("$($sbFilter.ToString()) -and `$PSItem.InternalCategory -notmatch `"$($sFilterInternalCategory)`"")
    }

    If ( -not $Update -and (Test-Path -Path "$($sInstanceRessourcesPath)\*")) {
        Remove-Item "$($sInstanceRessourcesPath)\*" -Force
    }

    If ( -not $Update -and (Test-Path -Path "$($sInstanceRessourcesPath)\*")) {
        Remove-Item "$($sInstanceRessourcesPath)\*" -Force
    }

    #If ( -not $Update -and (Test-Path -Path "$($sInstanceShadersPath)\*")) {
    #    Remove-Item "$($sInstanceShadersPath)\*" -Force
    #}

    ShowLogMessage "INFO" "We are going to copy new versions of mods to: $($InstancePath)" ([ref]$sLogFile)
    ShowLogMessage "DEBUG" "Set use      : $($PSCmdlet.ParameterSetName)" ([ref]$sLogFile)
    ShowLogMessage "OTHER" "" ([ref]$sLogFile)
}

PROCESS {

    $iCounter = 1
    $iNbToCopy = ($Mods | Where-Object $sbFilter).Count

    $Mods | Sort-Object Name | Where-Object $sbFilter | ForEach-Object {
        $iPercentComplete = [System.Math]::Round(($iCounter/$iNbToCopy) * 100, 2)
        Write-Progress -Activity "Copy new version of Minecraft Mods ($($iCounter)/$($iNbToCopy) - $($iPercentComplete) %)..." -Status "Mods: $($PSItem.Name)..." -PercentComplete $iPercentComplete

        $sFileName = $PSItem.FileName
        $sSourceFile = $PSItem.FilePath
        $sPreviousFileName = $PSItem.PreviousFileName

        switch ($PSItem.Type) {
            "Mods" {
                $sDestinationFile = "$($sInstanceModsPath)\$($sFileName)"
                If ( -not [System.Convert]::ToBoolean($PSItem.Add)) {
                    $sPreviousFilePath = "$($sInstanceModsPath)\$($sPreviousFileName)"
                    $sNewPreivousFilePath = "$($sPreviousFilePath).disabled"
                }
                Break
            }
            "Ressources" {
                $sDestinationFile = "$($sInstanceRessourcesPath)\$($sFileName)"
                If ( -not [System.Convert]::ToBoolean($PSItem.Add)) {
                    $sPreviousFilePath = "$($sInstanceRessourcesPath)\$($sPreviousFileName)"
                    $sNewPreivousFilePath = "$($sPreviousFilePath).disabled"
                }
                Break
            }
            "Shaders" {
                $sDestinationFile = "$($sInstanceShadersPath)\$($sFileName)"
                If ( -not [System.Convert]::ToBoolean($PSItem.Add)) {
                    $sPreviousFilePath = "$($sInstanceShadersPath)\$($sPreviousFileName)"
                    $sNewPreivousFilePath = "$($sPreviousFilePath).disabled"
                }
                Break
            }
            Default {
                $sDestinationFile = "$($sInstanceModsPath)\$($sFileName)"
                If ( -not [System.Convert]::ToBoolean($PSItem.Add)) {
                    $sPreviousFilePath = "$($sInstanceModsPath)\$($sPreviousFileName)"
                    $sNewPreivousFilePath = "$($sPreviousFilePath).disabled"
                }
            }
        }

        # Just to be able to see what happens!
        Start-Sleep -Seconds 1

        Try {
            # Rename previous file if Add -ne $True
            If ( -not [System.Convert]::ToBoolean($PSItem.Add)) {
                ShowLogMessage "DEBUG" "Rename $($sPreviousFilePath) to $($sNewPreivousFilePath)" ([ref]$sLogFile)
                If (Test-Path -Path $sPreviousFilePath) {
                    Rename-Item -Path $sPreviousFilePath -NewName $sNewPreivousFilePath -Force
                }
            } Else {
                ShowLogMessage "DEBUG" "Adding, nothing to rename." ([ref]$sLogFile)
            }

            # Copy new mod
            ShowLogMessage "DEBUG" "Copy $($sSourceFile) to $($sDestinationFile)" ([ref]$sLogFile)
            Copy-Item -Path $sSourceFile -Destination $sDestinationFile
        } Catch {
            $sErrorMessage = $PSItem.Exception.Message
            $sStackTrace = $PSItem.StackTrace
            ShowLogMessage "ERROR" "Error to update mod in the instance!" ([ref]$sLogFile)
            ShowLogMessage "DEBUG" "Details:" ([ref]$sLogFile)
            If ($PSBoundParameters['Debug']) {
                ShowLogMessage "OTHER" "`t$($sErrorMessage)" ([ref]$sLogFile)
                ShowLogMessage "OTHER" "`t$($sStackTrace)" ([ref]$sLogFile)
            }
        }

        $iCounter++
    }
    Write-Progress -Activity "Copy new version of Minecraft Mods ($($iCounter)/$($iNbToCopy) - $($iPercentComplete) %)..." -Completed
}
