<#
    .SYNOPSIS
        Get updated mods for Minecraft
    .DESCRIPTION
        From the csv '00_main_listing.csv' retrieve the latest version of each mods and download it.
        Generate some markdown and text file for the Gentlemen of Craft Discord server and our website.
    .PARAMETER MCVersion
        Version of Minecraft in the format 'x.x.x' the last digit is mandatory!
    .PARAMETER NoDownload
        Switch to inform the script to not download any mods.
        Useful to generate only the markdown or text files and see if everything works fine!
    .PARAMETER Discord
        Generate markdown file to copy/paste for Discord
    .PARAMETER Website
        Generate text file to copy/paste for Website
    .PARAMETER Copy
        Initiate copy to instance folder
    .PARAMETER Files
        Generate files for Discord and website
    .PARAMETER IgnoreQuilt
        Ignore the Quilt loader from settings
    .OUTPUTS
        Log file, markdown file for Gentlemen of Craft Discord server, text file to update the website and a csv with all the mods and information about them.
    .EXAMPLE
        .\Get-ModsNewVersion.ps1 -MCVersion "1.19.0"
    .EXAMPLE
        .\Get-ModsNewVersion.ps1 -MCVersion "1.19.0" -NoDownload
    .NOTES
        Name           : Get-ModsNewVersion
        Version        : 2.0b
        Created by     : Chucky2401
        Date created   : 13/07/2022
        Modified by    : Chucky2401
        Date modified  : 07/05/2023
        Change         : Add Modrinth source
    .LINK
        https://github.com/Chucky2401/Minecraft-Mods/blob/main/README.md#get-modsnewversion
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
Param (
    [Parameter(Mandatory = $True)]
    [ValidatePattern("\d+\.\d+\.\d+")]
    [string]$MCVersion,
    [Parameter(Mandatory = $False)]
    [switch]$NoDownload,
    [Parameter(Mandatory = $False)]
    [switch]$Discord,
    [Parameter(Mandatory = $False)]
    [switch]$Website,
    [Parameter(Mandatory = $False)]
    [switch]$Copy,
    [Parameter(Mandatory = $False)]
    [Switch]$Files,
    [Parameter(Mandatory = $False)]
    [Switch]$IgnoreQuilt
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action
$ErrorActionPreference = "Stop"

Import-Module -Name ".\inc\modules\Tjvs.Message", ".\inc\modules\Tjvs.Minecraft", ".\inc\modules\Tjvs.Settings"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

#----------------------------------------------------------[Declarations]----------------------------------------------------------
# Fichiers
## Directories
$sModsCsvListDirectory  = "$($PSScriptRoot)\csv"
$sModsMarkdownDirectory = "$($PSScriptRoot)\md"
$sModsTexteDirectory    = "$($PSScriptRoot)\txt"
## CSV
$aMainModsListFile    = "$($sModsCsvListDirectory)\00_main_listing.csv"
$aVersionModsListFile = "$($sModsCsvListDirectory)\MC_$($MCVersion)-$(Get-Date -Format "yyyy.MM.dd_HH.mm").csv"
## Markdown
$sMarkdownOptifine   = "$($sModsMarkdownDirectory)\MC_$($MCVersion)-Optifine-$(Get-Date -Format "yyyy.MM.dd_HH.mm").md"
$sMarkdownNoOptifine = "$($sModsMarkdownDirectory)\MC_$($MCVersion)-NoOptifine-$(Get-Date -Format "yyyy.MM.dd_HH.mm").md"
## Text
$sInfoWebSiteOptifine   = "$($sModsTexteDirectory)\MC_$($MCVersion)-Optifine-$(Get-Date -Format "yyyy.MM.dd_HH.mm").txt"
$sInfoWebSiteNoOptifine = "$($sModsTexteDirectory)\MC_$($MCVersion)-NoOptifine-$(Get-Date -Format "yyyy.MM.dd_HH.mm").txt"

# Mods
$aMainModsList            = Import-Csv -Path $aMainModsListFile -Delimiter ";" -Encoding utf8
$aPreviousModListDownload = $null
$aModListDownload         = @()
$aMarkdownModsOptifine    = @()
$aMarkdownModsOptifine   += "Mise à jour de **Nos Ressources Minecraft** - *$($mojangFormatVersion)* - (__{RECOMMANDATION}__)"
$aMarkdownModsNoOptifine  = @()
$aMarkdownModsNoOptifine += "Mise à jour de **Nos Ressources Minecraft Sans Optifine** - *$($mojangFormatVersion)* - (__{RECOMMANDATION}__)"
$aTexteModsOptifine       = @()
$aTexteModsNoOptifine     = @()

# Minecraft
$mojangFormatVersion = ""
If ($MCVersion -match "^(.+)\.0$") {
    $mojangFormatVersion = $MCVersion -replace "\.0$", ""
} Else {
    $mojangFormatVersion = $MCVersion
}

If ($IgnoreQuilt -and $global:settings.general.modLoaderType.Contains("Quilt")) {
    $global:settings.general.modLoaderType = $global:settings.general.modLoaderType | Where-Object { $PSItem -ne "Quilt" }
}

$global:settings.general.baseFolder += $MCVersion
$htDownloadDirectories = [ordered]@{
    BaseFolder              = "$($global:settings.general.baseFolder)"
    ModsFolder              = "$($global:settings.general.baseFolder)\Mods"
    ModsNoOptifineFolder    = "$($global:settings.general.baseFolder)\Mods\NoOptifine"
    ResourcesFolder         = "$($global:settings.general.baseFolder)\Resources"
    ShadersFolder           = "$($global:settings.general.baseFolder)\Shaders"
}

$htComplementFolders = [ordered]@{
    GocFolder               = "$($global:settings.general.baseFolder)\#GoC"
    GocModsFolder           = "$($global:settings.general.baseFolder)\#GoC\mods"
    GocModsNoOptifineFolder = "$($global:settings.general.baseFolder)\#GoC\modsNoOptifine"
    GocResourcesFolder      = "$($global:settings.general.baseFolder)\#GoC\resourcepacks"
    GocShadersFolder        = "$($global:settings.general.baseFolder)\#GoC\shaders"
}

# Logs
$sLogPath = "$($PSScriptRoot)\logs"
$sLogName = "MC_$($MCVersion)_download_mods-$(Get-Date -Format "yyyy.MM.dd_HH.mm").log"
$sLogFile = "$($sLogPath)\$($sLogName)"

# Divers
$iCompteur         = 0
$bPreviousDownload = $False
$bPreviousModFound = $null
$iMaxDownloadTry   = 3

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-CenterText "*************************************" $sLogFile
Write-CenterText "*                                   *" $sLogFile
Write-CenterText "*      Download MC $($MCVersion) Mods      *" $sLogFile
Write-CenterText "*             $(Get-Date -Format 'yyyy.MM.dd')            *" $sLogFile
Write-CenterText "*            Start $(Get-Date -Format 'HH:mm')            *" $sLogFile
Write-CenterText "*                                   *" $sLogFile
Write-CenterText "*************************************" $sLogFile

ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)

# Version directory exist
ShowLogMessage -type "INFO" -message "Testing if directory exist..." -sLogFile ([ref]$sLogFile)
## Mandatory folders
$htDownloadDirectories.GetEnumerator() | ForEach-Object {
    If (!(Test-Path "$($PSItem.Value)")) {
        ShowLogMessage -type "WARNING" -message "Folder '$($PSItem.Value)' does not exist !" -sLogFile ([ref]$sLogFile)
        ShowLogMessage -type "INFO" -message "Creating the folder..." -sLogFile ([ref]$sLogFile)
        Try {
            New-Item -Path "$($PSItem.Value)" -ItemType Directory -ErrorAction Stop | Out-Null
            ShowLogMessage -type "SUCCESS" -message "Folder '$($PSItem.Value)' created successfully!" -sLogFile ([ref]$sLogFile)
        } Catch {
            $sErrorMessage = $_.Exception.Message
            ShowLogMessage -type "ERROR" -message "Folder '$($PSItem.Value)' has not been created!" -sLogFile ([ref]$sLogFile)
            If ($PSBoundParameters['Debug']) {
                ShowLogMessage -type "DEBUG" -message "Error detail:" -sLogFile ([ref]$sLogFile)
                ShowLogMessage -type "OTHER" -message "`$($sErrorMessage)" -sLogFile ([ref]$sLogFile)
            }
    
            exit 0
        }
    } Else {
        ShowLogMessage -type "SUCCESS" -message "Folder '$($PSItem.Value)' exists!" -sLogFile ([ref]$sLogFile)
    }
}
## Optional folders
$htComplementFolders.GetEnumerator() | ForEach-Object {
    If (!(Test-Path "$($PSItem.Value)")) {
        ShowLogMessage -type "WARNING" -message "Folder '$($PSItem.Value)' does not exist !" -sLogFile ([ref]$sLogFile)
        ShowLogMessage -type "INFO" -message "Creating the folder..." -sLogFile ([ref]$sLogFile)
        Try {
            New-Item -Path "$($PSItem.Value)" -ItemType Directory -ErrorAction Stop | Out-Null
            ShowLogMessage -type "SUCCESS" -message "Folder '$($PSItem.Value)' created successfully!" -sLogFile ([ref]$sLogFile)
        } Catch {
            $sErrorMessage = $_.Exception.Message
            ShowLogMessage -type "ERROR" -message "Folder '$($PSItem.Value)' has not been created!" -sLogFile ([ref]$sLogFile)
            If ($PSBoundParameters['Debug']) {
                ShowLogMessage -type "DEBUG" -message "Error detail:" -sLogFile ([ref]$sLogFile)
                ShowLogMessage -type "OTHER" -message "`$($sErrorMessage)" -sLogFile ([ref]$sLogFile)
            }
    
            exit 0
        }
    } Else {
        ShowLogMessage -type "SUCCESS" -message "Folder '$($PSItem.Value)' exists!" -sLogFile ([ref]$sLogFile)
    }
}

ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)

# Previous download?
ShowLogMessage -type "INFO" -message "Checking if we already download mods..." -sLogFile ([ref]$sLogFile)
$oPreviousDownload = Get-ChildItem $($sModsCsvListDirectory) -Filter "MC_$($MCVersion)-*.csv" | Sort-Object LastWriteTime -Desc | Select-Object -First 1
If ($null -eq $oPreviousDownload) {
    ShowLogMessage -type "INFO" -message "No previous download..." -sLogFile ([ref]$sLogFile)
} Else {
    ShowLogMessage -type "INFO" -message "We already downloaded mods. We will download only new version" -sLogFile ([ref]$sLogFile)
    $aPreviousModListDownload = Import-Csv -Path $oPreviousDownload.FullName -Delimiter ";" -Encoding utf8
    $bPreviousDownload = $True
}

ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)

ShowLogMessage -type "INFO" -message "Download updated mods" -sLogFile ([ref]$sLogFile)
# Formatting boolean object
$isEnabled = @{ Label = "isEnabled" ; Expression = { [Boolean]::Parse($PSItem.enabled) } }
$isGoc     = @{ Label = "isGoc" ; Expression = { [Boolean]::Parse($PSItem.goc) } }
$toCopy    = @{ Label = "toCopy" ; Expression = { [Boolean]::Parse($PSItem.copy) } }
$aMainModsList = $aMainModsList | Select-Object -Property *, $isEnabled, $isGoc, $toCopy -ExcludeProperty enabled, goc, copy

# Downloading
$aMainModsList | Where-Object { $PSItem.isEnabled } | ForEach-Object {
    $bDownloadSuccess     = $False
    $iNumberDownloadTried = 1

    $iPercentComplete = [Math]::Round(($iCompteur/$aMainModsList.Length)*100,2)
    Write-Progress -Activity "Download updated mods ($($iPercentComplete)%)..." -PercentComplete $iPercentComplete -Status "Querying source Website for $($PSItem.name)..."

    # Wroking variables
    $sModId             = $PSItem.id
    $sModName           = $PSItem.name
    $bGoc               = $PSItem.isGoc
    $sModDisplayName    = $PSItem.displayName
    $sType              = $PSItem.type
    $sInternalCategory  = $PSItem.internalCategory
    $bCopy              = $PSItem.toCopy
    $sField             = $PSItem.versionField
    $sVersionPattern    = $PSItem.versionPattern
    $iSkip              = [int]$PSItem.skip
    $sVersionModsMc     = $mojangFormatVersion
    $sPreviousVersion   = ""
    $sFilePath          = ""
    $sPreviousFileName  = ""
    $bAdd               = $False
    $bPreviousModFound  = $False
    
    If ($PSItem.ForceMcVersion -ne "") {
        $sVersionModsMc = $PSItem.ForceMcVersion
    }

    ShowLogMessage -type "INFO" -message "Querying last file for $($sModName) (Loader: $($global:settings.general.modLoaderType[0]); MC Version: $($mojangFormatVersion))..." -sLogFile ([ref]$sLogFile)

    #If ($sModName -eq "Advancements Enlarger") {
    #    $dummy = $True
    #}

    switch ($PSItem.sourceWebsite) {
        "curseforge" {
            If ($sType -eq "Mods") {
                $oFileInfo = Get-InfoFromCurseForge -ModId $sModId -Skip $iSkip -VersionPattern $sVersionPattern -FieldVersion $sField -MCVersion $sVersionModsMc -MainModList $aMainModsList
            } Else {
                $oFileInfo = Get-InfoFromCurseForge -ModId $sModId -Skip $iSkip -VersionPattern $sVersionPattern -FieldVersion $sField -MCVersion $sVersionModsMc -MainModList $aMainModsList -Resources 
            }
        }
        "modrinth" {
            If ($sType -eq "Mods") {
                $oFileInfo = Get-InfoFromModrinth -ModId $sModId -Skip $iSkip -VersionPattern $sVersionPattern -FieldVersion $sField -MCVersion $sVersionModsMc -MainModList $aMainModsList
            } Else {
                $oFileInfo = Get-InfoFromModrinth -ModId $sModId -Skip $iSkip -VersionPattern $sVersionPattern -FieldVersion $sField -MCVersion $sVersionModsMc -MainModList $aMainModsList -Resources 
            }
        }
        "optifine" {
            $oFileInfo = Get-InfoOptifine -MCVersion $sVersionModsMc
        }
        "replaymod" {
            $oFileInfo = Get-InfoReplayMod -MCVersion $sVersionModsMc
        }
        "chocolateminecraft" {
            $oFileInfo = Get-InfoXaeroMod -MCVersion $sVersionModsMc -Mod $sModName
        }
        "fabricmc" {
            $oFileInfo = Get-InfoFabricLoader -MCVersion $sVersionModsMc
        }
        Default { $oFileInfo = $null }
    }

    Write-Progress -Activity "Download updated mods ($($iPercentComplete)%)..." -PercentComplete $iPercentComplete -Status "Checking update for $($PSItem.name)..."
    If ($null -ne $oFileInfo) {
        ShowLogMessage -type "INFO" -message "A file has been found!" -sLogFile ([ref]$sLogFile)

        # Mod path for download destination
        switch ($sType) {
            "Mods" {
                If ($sInternalCategory -eq "NoOptifine") {
                    $sFilePath = "$($htDownloadDirectories['ModsNoOptifineFolder'])\$($oFileInfo.filename)"
                } Else {
                    $sFilePath = "$($htDownloadDirectories['ModsFolder'])\$($oFileInfo.filename)"
                }
            }
            "Resources" {
                $sFilePath = "$($htDownloadDirectories['ResourcesFolder'])\$($oFileInfo.filename)"
            }
            "Shaders" {
                $sFilePath = "$($htDownloadDirectories['ShadersFolder'])\$($oFileInfo.filename)"
            }
            Default {
                $sFilePath = "$($htDownloadDirectories['ModsFolder'])\$($oFileInfo.filename)"
            }
        }

        If (!$bPreviousDownload) {
            ShowLogMessage -type "INFO" -message "No previous download. The file will be download..." -sLogFile ([ref]$sLogFile)
            $oModInfo = [PSCustomObject]@{
                Name             = $PSItem.displayName
                ModId            = $PSItem.id
                Version          = $oFileInfo.Version
                Type             = $sType
                InternalCategory = $sInternalCategory
                GOC              = $bGoc
                FileId           = $oFileInfo.id
                FileName         = $oFileInfo.filename
                FilePath         = $sFilePath
                PreviousFileName = ""
                FileDate         = $oFileInfo.fileDate
                FileLength       = $oFileInfo.fileLength
                DownloadUrl      = $oFileInfo.downloadUrl
                GameVersion      = $mojangFormatVersion
                Dependencies     = $sDependencies
                Copy             = $bCopy
                Add              = $True
                Update           = $True
            }
        } Else {
            ShowLogMessage -type "INFO" -message "A previous download exist. We will check if the mods was updated." -sLogFile ([ref]$sLogFile)
            If ($aPreviousModListDownload.FileId.IndexOf($oFileInfo.id.ToString()) -eq -1) {
                $aPreviousModListDownload | Where-Object { $PSItem.ModId -eq $sModId -and $PSItem.name -eq $sModDisplayName } | ForEach-Object {
                    If ($PSItem.FileId -ne "") {
                        $bPreviousModFound = $True
                        $sPreviousVersion  = $PSItem.Version
                        $sPreviousFileName = $PSItem.FileName
                        $bPreviousModFound | Out-Null #To remove Warning
                        $sPreviousFileName | Out-Null #To remove Warning
                        ShowLogMessage -type "INFO" -message "The mods has been updated! ($($sPreviousVersion) -> $($oFileInfo.Version))" -sLogFile ([ref]$sLogFile)
                    } Else {
                        ShowLogMessage -type "INFO" -message "The mods has been updated for Minecraft $($mojangFormatVersion)!" -sLogFile ([ref]$sLogFile)
                    }
                }
                
                If (!$bPreviousModFound) {
                    $bAdd = $True
                    ShowLogMessage -type "INFO" -message "This is a new mod to download!" -sLogFile ([ref]$sLogFile)
                }
                $bFileUpdate = $True
            } Else {
                ShowLogMessage -type "INFO" -message "There is no modification for this mod. We will not download it again." -sLogFile ([ref]$sLogFile)
                $bFileUpdate = $False
            }

            $oModInfo = [PSCustomObject]@{
                Name             = $PSItem.displayName
                ModId            = $PSItem.id
                Version          = $oFileInfo.Version
                Type             = $sType
                InternalCategory = $sInternalCategory
                GOC              = $bGoc
                FileId           = $oFileInfo.id
                FileName         = $oFileInfo.filename
                FilePath         = $sFilePath
                PreviousFileName = $sPreviousFileName
                FileDate         = $oFileInfo.fileDate
                FileLength       = $oFileInfo.fileLength
                DownloadUrl      = $oFileInfo.downloadUrl
                GameVersion      = $mojangFormatVersion
                Dependencies     = $sDependencies
                Copy             = $bCopy
                Add              = $bAdd
                Update           = $bFileUpdate
            }
        }
    } Else {
        ShowLogMessage -type "WARNING" -message "No files found." -sLogFile ([ref]$sLogFile)
        $oModInfo = [PSCustomObject]@{
            Name             = $PSItem.displayName
            ModId            = $PSItem.id
            Version          = ""
            Type             = $sType
            InternalCategory = $sInternalCategory
            GOC              = $bGoc
            FileId           = ""
            FileName         = ""
            FilePath         = ""
            PreviousFileName = ""
            FileDate         = ""
            FileLength       = ""
            DownloadUrl      = ""
            GameVersion      = ""
            Dependencies     = ""
            Copy             = $bCopy
            Add              = $False
            Update           = $False
        }
    }

    If ($oModInfo.Update -and !$NoDownload) {
        # Rename previous file if exist
        If ($oModInfo.PreviousFileName -ne "") {
            ShowLogMessage -type "INFO" -message "A previous file exist. Renaming..." -sLogFile ([ref]$sLogFile)
            $sPreviousFilePath = $oModInfo.FilePath -replace "$([Regex]::Escape($oModInfo.FileName))", "$($oModInfo.PreviousFileName)"
            $sNewPreviousFilePath = "$($sPreviousFilePath).old"
            Try {
                Rename-Item -Path $sPreviousFilePath -NewName $sNewPreviousFilePath -Force -ErrorAction Stop
                ShowLogMessage -type "SUCCESS" -message "Previous file has been renamed!" -sLogFile ([ref]$sLogFile)
            } Catch {
                $sErrorMessage = $_.Exception.Message
                $sStackTrace = $_.ScriptStackTrace
                ShowLogMessage -type "WARNING" -message "Previous file has not been renamed!" -sLogFile ([ref]$sLogFile)
                ShowLogMessage -type "DEBUG" -message "Details:" -sLogFile ([ref]$sLogFile)
                If ($PSBoundParameters['Debug']) {
                    ShowLogMessage -type "OTHER" -message "`t$($sErrorMessage)`n`t$($sStackTrace)" -sLogFile ([ref]$sLogFile)
                }
            }
        }
        
        # Downloading
        Write-Progress -Activity "Download updated mods..." -PercentComplete $iPercentComplete -Status "Downloading $($PSItem.name)..."
        do {
            ShowLogMessage -type "INFO" -message "(Try #$($iNumberDownloadTried)) Downloading the new version of the mod..." -sLogFile ([ref]$sLogFile)
            Try {
                If ($PSItem.sourceWebsite -ne "chocolateminecraft") {
                    Start-BitsTransfer -Source $oModInfo.DownloadUrl -Destination $oModInfo.FilePath -Description "Downloading $($oModInfo.filename)" -ErrorAction Stop
                } Else {
                    Invoke-WebRequest -Uri $oModInfo.DownloadUrl -OutFile $oModInfo.FilePath -Method Post -ErrorAction Stop
                }
                $bDownloadSuccess = $True
                # We change LastWriteTime to today
                ([System.IO.FileInfo]$oModInfo.FilePath).LastWriteTime = Get-Date
                ShowLogMessage -type "SUCCESS" -message "The mod has been downloaded successfully!" -sLogFile ([ref]$sLogFile)
            } Catch {
                $iNumberDownloadTried++
                $sErrorMessage = $PSItem.Exception.Message
                ShowLogMessage -type "ERROR" -message "The mod has not been downloaded!" -sLogFile ([ref]$sLogFile)
                If ($PSBoundParameters['Debug']) {
                    ShowLogMessage -type "OTHER" -message "Error detail:" -sLogFile ([ref]$sLogFile)
                    ShowLogMessage -type "OTHER" -message "`t$($sErrorMessage)" -sLogFile ([ref]$sLogFile)
                }
            }
        } While (-not $bDownloadSuccess -and $iNumberDownloadTried -le $iMaxDownloadTry)

        If (-not $bDownloadSuccess -and $iNumberDownloadTried -gt $iMaxDownloadTry) {
            ShowLogMessage -type "ERROR" -message "Too many tries!" -sLogFile ([ref]$sLogFile)
        }
    } ElseIf ($oModInfo.Update -and $NoDownload) {
        ShowLogMessage -type "DEBUG" -message "We should download $($oModInfo.DownloadUrl) to $($oModInfo.FilePath)" -sLogFile ([ref]$sLogFile)
    }

    # Fill the array for the markdown text and text for the website depending InternalCategory and Add only if the object has 'Update' is True
    # If you use the switch 'NoDownload' is used, this is for testing purpose only !
    If ($oModInfo.Update -and $oModInfo.GOC) {
        Write-Progress -Activity "Download updated mods ($($iPercentComplete)%)..." -PercentComplete $iPercentComplete -Status "Information text for $($PSItem.name)..."

        If ($oModInfo.Add -and $oModInfo.InternalCategory -ne "NoOptifine") {
            $aMarkdownModsOptifine += "`t* ``AJOUT`` : **$($oModInfo.Name)** en version *$($oModInfo.Version)*"
            $aTexteModsOptifine += "$($oModInfo.Name) ($($oModInfo.Version)): $($oModInfo.DownloadUrl)"
        } ElseIf (!$oModInfo.Add -and $oModInfo.InternalCategory -ne "NoOptifine") {
            $aMarkdownModsOptifine += "`t* ``M à J`` : **$($oModInfo.Name)** change de version *$($sPreviousVersion)* -> *$($oModInfo.Version)*"
            $aTexteModsOptifine += "$($oModInfo.Name) ($($oModInfo.Version)): $($oModInfo.DownloadUrl)"
        } ElseIf ($oModInfo.Add -and $oModInfo.InternalCategory -eq "NoOptifine") {
            $aMarkdownModsNoOptifine += "`t* ``AJOUT`` : **$($oModInfo.Name)** en version *$($oModInfo.Version)*"
            $aTexteModsNoOptifine += "$($oModInfo.Name) ($($oModInfo.Version)): $($oModInfo.DownloadUrl)"
        } Else {
            $aMarkdownModsNoOptifine += "`t* ``M à J`` : **$($oModInfo.Name)** change de version *$($sPreviousVersion)* -> *$($oModInfo.Version)*"
            $aTexteModsNoOptifine += "$($oModInfo.Name) ($($oModInfo.Version)): $($oModInfo.DownloadUrl)"
        }
    }
    
    $aModListDownload += $oModInfo
    $iCompteur++

    ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)
}
Write-Progress -Activity "Download updated mods ($($iPercentComplete)%)..." -Completed

# Finalizing markdown lines
$aMarkdownModsOptifine += "`t* ``M à J`` : Archive contenant tous les mods"
$aMarkdownModsOptifine += "`t* ``M à J`` : Archive contenant tous les **mods** et toutes les **textures**"
$aMarkdownModsNoOptifine += "`t* ``M à J`` : Archive contenant tous les mods"
$aMarkdownModsNoOptifine += "`t* ``M à J`` : Archive contenant tous les **mods** et toutes les **textures**"

If ($Files) {
    ShowLogMessage -type "INFO" -message "Export mods session information to CSV '$($aVersionModsListFile)'" -sLogFile ([ref]$sLogFile)
    Try {
        $aModListDownload | Export-CSV -Path $aVersionModsListFile -Delimiter ";" -Encoding utf8 -NoTypeInformation -ErrorAction Stop
        ShowLogMessage -type "SUCCESS" -message "Mods list has been exported successfully!" -sLogFile ([ref]$sLogFile)
    } Catch {
        $sErrorMessage = $_.Exception.Message
        ShowLogMessage -type "ERROR" -message "Mods list has not been exported!" -sLogFile ([ref]$sLogFile)
        If ($PSBoundParameters['Debug']) {
            ShowLogMessage -type "DEBUG" -message "Error detail:" -sLogFile ([ref]$sLogFile)
            ShowLogMessage -type "OTHER" -message "`$($sErrorMessage)" -sLogFile ([ref]$sLogFile)
        }
    }
}

If ($Discord -and $Files) {
    ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)
    
    ShowLogMessage -type "INFO" -message "Export Discord markdown lines to files..." -sLogFile ([ref]$sLogFile)
    $aMarkdownModsOptifine | Out-File -FilePath $sMarkdownOptifine
    $aMarkdownModsNoOptifine | Out-File -FilePath $sMarkdownNoOptifine
}

If ($Website -and $Files) {
    ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)
    
    ShowLogMessage -type "INFO" -message "Export website text lines to files..." -sLogFile ([ref]$sLogFile)
    $aTexteModsOptifine | Out-File -FilePath $sInfoWebSiteOptifine
    $aTexteModsNoOptifine | Out-File -FilePath $sInfoWebSiteNoOptifine
}

ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)
ShowLogMessage -type "OTHER" -message "------------------------------------------------------------" -sLogFile ([ref]$sLogFile)
ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)

# Show Summary for manual copy
ShowLogMessage -type "INFO" -message "Summary:" -sLogFile ([ref]$sLogFile)
ShowLogMessage -type "OTHER" -message "`tMods GoC:" -sLogFile ([ref]$sLogFile)
$aModListDownload | Where-Object { $PSItem.Update -eq $True -and $PSItem.Type -eq "Mods" -and $PSItem.InternalCategory -ne "NoOptifine" -and $PSItem.GOC -eq $True } | ForEach-Object {
    ShowLogMessage -type "OTHER" -message "`t`t$($PSItem.FileName)" -sLogFile ([ref]$sLogFile)
}

ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)

ShowLogMessage -type "OTHER" -message "`tMods GoC No Optifine:" -sLogFile ([ref]$sLogFile)
$aModListDownload | Where-Object { $PSItem.Update -eq $True -and $PSItem.Type -eq "Mods" -and $PSItem.InternalCategory -eq "NoOptifine" -and $PSItem.GOC -eq $True } | ForEach-Object {
    ShowLogMessage -type "OTHER" -message "`t`t$($PSItem.FileName)" -sLogFile ([ref]$sLogFile)
}

ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)

ShowLogMessage -type "OTHER" -message "`tRessources GoC:" -sLogFile ([ref]$sLogFile)
$aModListDownload | Where-Object { $PSItem.Update -eq $True -and $PSItem.Type -eq "Resources" -and $PSItem.GOC -eq $True } | ForEach-Object {
    ShowLogMessage -type "OTHER" -message "`t`t$($PSItem.FileName)" -sLogFile ([ref]$sLogFile)
}

ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)

ShowLogMessage -type "OTHER" -message "`tShaders GoC:" -sLogFile ([ref]$sLogFile)
$aModListDownload | Where-Object { $PSItem.Update -eq $True -and $PSItem.Type -eq "Shaders" -and $PSItem.GOC -eq $True } | ForEach-Object {
    ShowLogMessage -type "OTHER" -message "`t`t$($PSItem.FileName)" -sLogFile ([ref]$sLogFile)
}

ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)
ShowLogMessage -type "OTHER" -message "------------------------------------------------------------" -sLogFile ([ref]$sLogFile)
ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)

## My copy
If ($Copy) {
    #ShowLogMessage -type "INFO" -message "Copy GoC Mods..." -sLogFile ([ref]$sLogFile)
    #$aModListDownload | .\Copy-ToMinecraftInstance.ps1 -InstancePath "E:\Games\Minecraft\#MultiMC\instances\1.19-Opti\.minecraft" -InternalCategoryExclude "NoOptifine" -GoCOnly -Update $bPreviousDownload -LogFile $sLogFile -Debug

    #ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)
    #
    #ShowLogMessage -type "INFO" -message "Copy not GoC Mods..." -sLogFile ([ref]$sLogFile)
    #$aModListDownload | .\Copy-ToMinecraftInstance.ps1 -InstancePath "E:\Games\Minecraft\#MultiMC\instances\1.19-TestMods\.minecraft" -InternalCategoryExclude "Optifine" -Update $bPreviousDownload -LogFile $sLogFile -Debug

    #ShowLogMessage -type "OTHER" -message "" -sLogFile ([ref]$sLogFile)

    $settings.copy | ForEach-Object {
        $instancePath = $PSItem.instancePath
        $exclude = $PSItem.categoryExclude
        $gocOnly = $PSItem.gocOnly

        Write-Message -Type "INFO" -Message "Copy mods to $($instancePath)..." -LogFile ([ref]$sLogFile)
        $aModListDownload | .\Copy-ToMinecraftInstance.ps1 -InstancePath $instancePath -InternalCategoryExclude $exclude -GoCOnly:$gocOnly -Update $bPreviousDownload -LogFile $sLogFile -Debug
    }
}

Write-CenterText "*************************************" $sLogFile
Write-CenterText "*                                   *" $sLogFile
Write-CenterText "*      Download MC $($MCVersion) Mods      *" $sLogFile
Write-CenterText "*             $(Get-Date -Format 'yyyy.MM.dd')            *" $sLogFile
Write-CenterText "*             End $(Get-Date -Format 'HH:mm')             *" $sLogFile
Write-CenterText "*                                   *" $sLogFile
Write-CenterText "*************************************" $sLogFile
