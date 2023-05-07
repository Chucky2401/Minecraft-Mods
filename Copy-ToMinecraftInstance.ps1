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
        Precise directly the folder to the Minecraft Instance (this folder must contains `mods`, `resourcepacks` and `shaderpacks` folders)
    .PARAMETER IncludeIncludeBaseMods
        Include base mods (with internal category empty) to the filter
    .PARAMETER InternalCategoryExclude
        Array of string to exclude one or more InternalCategory
    .PARAMETER InternalCategoryInclude
        Array of string to include one or more InternalCategory
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
        Version        : 1.3
        Created by     : Chucky2401
        Date Created   : 14/08/2022
        Modify by      : Chucky2401
        Date modified  : 18/12/2022
        Change         : Use modules instead of local functions
                         Add '-InternalCategoryInclude' and '-IncludeBaseMods' parameters
                         Unify version number
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
    [Switch]$IncludeBaseMods,
    [Parameter(ParameterSetName = "Pipeline")]
    [Parameter(ParameterSetName = "File")]
    [String[]]$InternalCategoryExclude,
    [Parameter(ParameterSetName = "Pipeline")]
    [Parameter(ParameterSetName = "File")]
    [String[]]$InternalCategoryInclude,
    [Parameter(ParameterSetName = "Pipeline")]
    [Parameter(ParameterSetName = "File")]
    [Switch]$GoCOnly,
    [Parameter(ParameterSetName = "Pipeline")]
    [Parameter(ParameterSetName = "File")]
    [Boolean]$Update = $True,
    [Parameter(ParameterSetName = "Pipeline")]
    [String]$LogFile = (New-TemporaryFile)
)

BEGIN {
    #---------------------------------------------------------[Initialisations]--------------------------------------------------------

    #Set Error Action
    $ErrorActionPreference      = "Stop"
    If ($PSBoundParameters['Debug']) {
        $DebugPreference = "Continue"
    } Else {
        $DebugPreference = "SilentlyContinue"
    }

    Add-Type -AssemblyName System.Windows.Forms

    Import-Module -Name ".\inc\modules\Tjvs.Message", ".\inc\modules\Tjvs.Settings"

    #-----------------------------------------------------------[Functions]------------------------------------------------------------

    #----------------------------------------------------------[Declarations]----------------------------------------------------------

    #$htSettings = Get-Settings "$($PSScriptRoot)\conf\settings.ini" -StartBlock "Copy"

    # To don't change anything to my snippets! ;-)
    $sLogFile = $LogFile

    [ScriptBlock]$sbFilter = {[System.Convert]::ToBoolean($PSItem.Update)}

    If ($GoCOnly) {
        [ScriptBlock]$sbFilter = [ScriptBlock]::Create("$($sbFilter.ToString()) -and `$PSItem.GoC -eq `$True")
    }

    #-----------------------------------------------------------[Execution]------------------------------------------------------------

    If ($InstancePath -eq "") {
        $oFolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
            InitialDirectory = "$($global:settings.minecraft.baseFolder)"
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
        $sFilterExcludeInternalCategory = "\b$([String]::Join("\b|\b", $InternalCategoryExclude))\b"
        [ScriptBlock]$sbFilter = [ScriptBlock]::Create("$($sbFilter.ToString()) -and `$PSItem.InternalCategory -notmatch `"$($sFilterExcludeInternalCategory)`"")
    }

    If ($InternalCategoryInclude.Count -ge 1) {
        $sFilterIncludeInternalCategory = "\b$([String]::Join("\b|\b", $InternalCategoryInclude))\b"
        [ScriptBlock]$sbFilter = [ScriptBlock]::Create("$($sbFilter.ToString()) -and `$PSItem.InternalCategory -match `"$($sFilterIncludeInternalCategory)`" -or [String]::IsNullOrEmpty(`$PSItem.InternalCategory)")
    }

    If ($IncludeBaseMods) {
        [ScriptBlock]$sbFilter = [ScriptBlock]::Create("$($sbFilter.ToString()) -or [String]::IsNullOrEmpty(`$PSItem.InternalCategory)")
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

    ShowLogMessage -type "INFO" -message "We are going to copy new versions of mods to: $($InstancePath)" -sLogFile ([ref]$sLogFile)
    ShowLogMessage -type "DEBUG" -message "Set use      : $($PSCmdlet.ParameterSetName)" -sLogFile ([ref]$sLogFile)
    ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)
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
            "Resources" {
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
                ShowLogMessage -type "DEBUG" -message "Rename $($sPreviousFilePath) to $($sNewPreivousFilePath)" -sLogFile ([ref]$sLogFile)
                If (Test-Path -Path $sPreviousFilePath) {
                    Rename-Item -Path $sPreviousFilePath -NewName $sNewPreivousFilePath -Force
                }
            } Else {
                ShowLogMessage -type "DEBUG" -message "Adding, nothing to rename." -sLogFile ([ref]$sLogFile)
            }

            # Copy new mod
            ShowLogMessage -type "DEBUG" -message "Copy $($sSourceFile) to $($sDestinationFile)" -sLogFile ([ref]$sLogFile)
            Copy-Item -Path $sSourceFile -Destination $sDestinationFile -Force
        } Catch {
            $sErrorMessage = $PSItem.Exception.Message
            $sStackTrace = $PSItem.StackTrace
            ShowLogMessage -type "ERROR" -message "Error to update mod in the instance!" -sLogFile ([ref]$sLogFile)
            ShowLogMessage -type "DEBUG" -message "Details:" -sLogFile ([ref]$sLogFile)
            If ($PSBoundParameters['Debug']) {
                ShowLogMessage -type "OTHER" -message "`t$($sErrorMessage)" -sLogFile ([ref]$sLogFile)
                ShowLogMessage -type "OTHER" -message "`t$($sStackTrace)" -sLogFile ([ref]$sLogFile)
            }
        }

        $iCounter++
    }
    Write-Progress -Activity "Copy new version of Minecraft Mods ($($iCounter)/$($iNbToCopy) - $($iPercentComplete) %)..." -Completed
}
