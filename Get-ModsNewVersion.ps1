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
    .OUTPUTS
        Log file, markdown file for Gentlemen of Craft Discord server, text file to update the website and a csv with all the mods and information about them.
    .EXAMPLE
        .\Get-ModsNewVersion.ps1 -MCVersion "1.19.0"
    .EXAMPLE
        .\Get-ModsNewVersion.ps1 -MCVersion "1.19.0" -NoDownload
    .NOTES
        Name           : Get-ModsNewVersion
        Version        : 1.3
        Created by     : Chucky2401
        Date created   : 13/07/2022
        Modified by    : Chucky2401
        Date modified  : 18/12/2022
        Change         : Use modules instead of local functions
                         Add 'NoFile' and 'Copy parameters
                         Add up to 3 tries to download a mod
                         Typo fix
                         Missing 'ressource' replaced by 'resource'
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
    [Switch]$Files
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action
$ErrorActionPreference = "Stop"

Import-Module -Name ".\inc\modules\Tjvs.Message", ".\inc\modules\Tjvs.Minecraft", ".\inc\modules\Tjvs.Settings"

#-----------------------------------------------------------[Functions]------------------------------------------------------------

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# User settings
#$htSettings = Get-Settings "$($PSScriptRoot)\conf\settings.ini"

# API
#$sBaseUri         = "https://api.curseforge.com"
#$sBaseModFilesUri = "/v1/mods/{modId}/files"
#$oHeadersQuery    = @{
#    "Accept"    = "application/json"
#    "x-api-key" = $global:settings.curseforge.tokenValue
#}
#$oParametersQueryFiles = @{
#    Header      = $oHeadersQuery
#    Method      = "GET"
#    Uri         = ""
#    ContentType = "application/json"
#}

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
#$aRelationType            = @(
#    'None'
#    'Embedded Library'
#    'Optional Dependency'
#    'Required Dependency'
#    'Tool'
#    'Incompatible'
#    'Include'
#)
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
$htBoolean         = @{
    True  = $True
    False = $False
}
$iMaxDownloadTry = 3

#-----------------------------------------------------------[Execution]------------------------------------------------------------

Write-CenterText "*************************************" $sLogFile
Write-CenterText "*                                   *" $sLogFile
Write-CenterText "*      Download MC $($MCVersion) Mods      *" $sLogFile
Write-CenterText "*             $(Get-Date -Format 'yyyy.MM.dd')            *" $sLogFile
Write-CenterText "*            Start $(Get-Date -Format 'HH:mm')            *" $sLogFile
Write-CenterText "*                                   *" $sLogFile
Write-CenterText "*************************************" $sLogFile

ShowLogMessage "OTHER" "" ([ref]$sLogFile)

# Version directory exist
ShowLogMessage "INFO" "Testing if directory exist..." ([ref]$sLogFile)
## Mandatory folders
$htDownloadDirectories.GetEnumerator() | ForEach-Object {
    If (!(Test-Path "$($PSItem.Value)")) {
        ShowLogMessage "WARNING" "Folder '$($PSItem.Value)' does not exist !" ([ref]$sLogFile)
        ShowLogMessage "INFO" "Creating the folder..." ([ref]$sLogFile)
        Try {
            New-Item -Path "$($PSItem.Value)" -ItemType Directory -ErrorAction Stop | Out-Null
            ShowLogMessage "SUCCESS" "Folder '$($PSItem.Value)' created successfully!" ([ref]$sLogFile)
        } Catch {
            $sErrorMessage = $_.Exception.Message
            ShowLogMessage "ERROR" "Folder '$($PSItem.Value)' has not been created!" ([ref]$sLogFile)
            If ($PSBoundParameters['Debug']) {
                ShowLogMessage "DEBUG" "Error detail:" ([ref]$sLogFile)
                ShowLogMessage "OTHER" "`$($sErrorMessage)" ([ref]$sLogFile)
            }
    
            exit 0
        }
    } Else {
        ShowLogMessage "SUCCESS" "Folder '$($PSItem.Value)' exists!" ([ref]$sLogFile)
    }
}
## Optional folders
$htComplementFolders.GetEnumerator() | ForEach-Object {
    If (!(Test-Path "$($PSItem.Value)")) {
        ShowLogMessage "WARNING" "Folder '$($PSItem.Value)' does not exist !" ([ref]$sLogFile)
        ShowLogMessage "INFO" "Creating the folder..." ([ref]$sLogFile)
        Try {
            New-Item -Path "$($PSItem.Value)" -ItemType Directory -ErrorAction Stop | Out-Null
            ShowLogMessage "SUCCESS" "Folder '$($PSItem.Value)' created successfully!" ([ref]$sLogFile)
        } Catch {
            $sErrorMessage = $_.Exception.Message
            ShowLogMessage "ERROR" "Folder '$($PSItem.Value)' has not been created!" ([ref]$sLogFile)
            If ($PSBoundParameters['Debug']) {
                ShowLogMessage "DEBUG" "Error detail:" ([ref]$sLogFile)
                ShowLogMessage "OTHER" "`$($sErrorMessage)" ([ref]$sLogFile)
            }
    
            exit 0
        }
    } Else {
        ShowLogMessage "SUCCESS" "Folder '$($PSItem.Value)' exists!" ([ref]$sLogFile)
    }
}

ShowLogMessage "OTHER" "" ([ref]$sLogFile)

# Previous download?
ShowLogMessage "INFO" "Checking if we already download mods..." ([ref]$sLogFile)
$oPreviousDownload = Get-ChildItem $($sModsCsvListDirectory) -Filter "MC_$($MCVersion)-*.csv" | Sort-Object LastWriteTime -Desc | Select-Object -First 1
If ($null -eq $oPreviousDownload) {
    ShowLogMessage "INFO" "No previous download..." ([ref]$sLogFile)
} Else {
    ShowLogMessage "INFO" "We already downloaded mods. We will download only new version" ([ref]$sLogFile)
    $aPreviousModListDownload = Import-Csv -Path $oPreviousDownload.FullName -Delimiter ";" -Encoding utf8
    $bPreviousDownload = $True
}

ShowLogMessage "OTHER" "" ([ref]$sLogFile)

ShowLogMessage "INFO" "Download updated mods" ([ref]$sLogFile)
# Downloading
$aMainModsList | ForEach-Object {
    $bDownloadSuccess     = $False
    $iNumberDownloadTried = 1

    $iPercentComplete = [Math]::Round(($iCompteur/$aMainModsList.Length)*100,2)
    Write-Progress -Activity "Download updated mods ($($iPercentComplete)%)..." -PercentComplete $iPercentComplete -Status "Querying source Website for $($PSItem.name)..."

    # Wroking variables
    $sModId             = $PSItem.id
    $sModName           = $PSItem.name
    $bGoc               = $htBoolean[$PSItem.goc]
    $sModDisplayName    = $PSItem.displayName
    $sType              = $PSItem.type
    $sInternalCategory  = $PSItem.internalCategory
    $bCopy              = $htBoolean[$PSItem.copy]
    $sField             = $PSItem.versionField
    $sVersionPattern    = $PSItem.versionPattern
    #$iSkip              = [int]$PSItem.skip
    $sVersionModsMc     = $mojangFormatVersion
    $sPreviousVersion   = ""
    $sFilePath          = ""
    $sPreviousFileName  = ""
    #$aDependencies      = @()
    $bAdd               = $False
    $bPreviousModFound  = $False
    
    If ($PSItem.ForceMcVersion -ne "") {
        $sVersionModsMc = $PSItem.ForceMcVersion
    }

    ShowLogMessage "INFO" "Querying last file for $($sModName) (Loader: $($global:settings.general.modLoaderType); MC Version: $($mojangFormatVersion))..." ([ref]$sLogFile)

    switch ($PSItem.sourceWebsite) {
        "curseforge" {
            If ($sType -eq "Mods") {
                #$oParametersQueryFiles.Uri = "$($sBaseUri)$($sBaseModFilesUri.Replace("{modId}", $sModId))?gameVersion=$($sVersionModsMc)&modLoaderType=$($global:settings.general.modLoaderType)"
                $oFileInfo = Get-InfoFromCruseForge -ModId $sModId -VersionPattern $sVersionPattern -FieldVersion $sField -MCVersion $sVersionModsMc -MainModList $aMainModsList
            } Else {
                #$oParametersQueryFiles.Uri = "$($sBaseUri)$($sBaseModFilesUri.Replace("{modId}", $sModId))?gameVersion=$($sVersionModsMc)"
                $oFileInfo = Get-InfoFromCruseForge -ModId $sModId -VersionPattern $sVersionPattern -FieldVersion $sField -MCVersion $sVersionModsMc -MainModList $aMainModsList -Resources 
            }
            #$oResult = Invoke-RestMethod @oParametersQueryFiles
            #$oFileInfo = $oResult.data | Where-Object { $PSItem.gameVersions -match "$([Regex]::Escape($sVersionModsMc))$" } | Sort-Object fileDate -Desc | Select-Object -Skip #$iSkip -First 1
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
        ShowLogMessage "INFO" "A file has been found!" ([ref]$sLogFile)

        # Format dependencies
        #$oFileInfo.dependencies | Where-Object { $PSItem.relationType -match "3|4" } | ForEach-Object {
        #    $iModId = $PSItem.modId
        #    $sModName = ($aMainModsList | Where-Object { $PSItem.id -eq $iModId }).displayName
        #    If ($sModName -eq "" -or $null -eq $sModName) {
        #        $sModName = "{Unknow_$($iModId)}"
        #    }
        #    $sRelation = $aRelationType[$PSItem.relationType]
        #    $aDependencies += "$($sModName)($($sRelation))"
        #}
        #$sDependencies = [String]::Join("/", $aDependencies)

        # Get mod version
        #If ($sVersionPattern -ne "" -or $null -eq $sVersionPattern) {
        #    $aMatchesVersion = $oFileInfo.$($sField) | Select-String -Pattern $sVersionPattern
        #    If ($aMatchesVersion.Length -ge 1) {
        #        $sVersion = $aMatchesVersion.Matches.Groups[1].Value
        #    } Else {
        #        ShowLogMessage "ERROR" "Cannot found version from $($sField) with pattern $($sVersionPattern)!" ([ref]$sLogFile)
        #        $sVersion = "x.x.x"
        #    }
        #} Else {
        #    $sVersion = ""
        #}

        # Check download URL
        #If ($oFileInfo.downloadUrl -eq "" -or $null -eq $oFileInfo.downloadUrl) {
        #    $sIdFirstPart = ($oFileInfo.id).ToString().Substring(0, 4)
        #    $sIdSecondPart = ($oFileInfo.id).ToString().Substring(4)
        #    $oFileInfo.downloadUrl = "https://edge.forgecdn.net/files/$($sIdFirstPart)/$($sIdSecondPart)/$($oFileInfo.fileName)"
        #}

        # Mod path for download destination
        switch ($sType) {
            "Mods" {
                If ($sInternalCategory -eq "NoOptifine") {
                    $sFilePath = "$($htDownloadDirectories['ModsNoOptifineFolder'])\$($oFileInfo.filename)"
                } Else {
                    $sFilePath = "$($htDownloadDirectories['ModsFolder'])\$($oFileInfo.filename)"
                }
            }
            "Ressources" {
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
            ShowLogMessage "INFO" "No previous download. The file will be download..." ([ref]$sLogFile)
            $oModInfo = [PSCustomObject]@{
                Name             = $PSItem.displayName
                ModId            = $PSItem.id
                Version          = $sVersion
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
            ShowLogMessage "INFO" "A previous download exist. We will check if the mods was updated." ([ref]$sLogFile)
            If ($aPreviousModListDownload.FileId.IndexOf($oFileInfo.id.ToString()) -eq -1) {
                $aPreviousModListDownload | Where-Object { $PSItem.ModId -eq $sModId -and $PSItem.name -eq $sModDisplayName } | ForEach-Object {
                    If ($PSItem.FileId -ne "") {
                        $bPreviousModFound = $True
                        $sPreviousVersion  = $PSItem.Version
                        $sPreviousFileName = $PSItem.FileName
                        $bPreviousModFound | Out-Null #To remove Warning
                        $sPreviousFileName | Out-Null #To remove Warning
                        ShowLogMessage "INFO" "The mods has been updated! ($($sPreviousVersion) -> $($sVersion))" ([ref]$sLogFile)
                    } Else {
                        ShowLogMessage "INFO" "The mods has been updated for Minecraft $($mojangFormatVersion)!" ([ref]$sLogFile)
                    }
                }
                
                If (!$bPreviousModFound) {
                    $bAdd = $True
                    ShowLogMessage "INFO" "This is a new mod to download!" ([ref]$sLogFile)
                }
                $bFileUpdate = $True
            } Else {
                ShowLogMessage "INFO" "There is no modification for this mod. We will not download it again." ([ref]$sLogFile)
                $bFileUpdate = $False
            }

            $oModInfo = [PSCustomObject]@{
                Name             = $PSItem.displayName
                ModId            = $PSItem.id
                Version          = $sVersion
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
        ShowLogMessage "WARNING" "No files found." ([ref]$sLogFile)
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
            ShowLogMessage "INFO" "A previous file exist. Renaming..." ([ref]$sLogFile)
            $sPreviousFilePath = $oModInfo.FilePath -replace "$([Regex]::Escape($oModInfo.FileName))", "$($oModInfo.PreviousFileName)"
            $sNewPreviousFilePath = "$($sPreviousFilePath).old"
            Try {
                Rename-Item -Path $sPreviousFilePath -NewName $sNewPreviousFilePath -Force -ErrorAction Stop
                ShowLogMessage "SUCCESS" "Previous file has been renamed!" ([ref]$sLogFile)
            } Catch {
                $sErrorMessage = $_.Exception.Message
                $sStackTrace = $_.ScriptStackTrace
                ShowLogMessage "WARNING" "Previous file has not been renamed!" ([ref]$sLogFile)
                ShowLogMessage "DEBUG" "Details:" ([ref]$sLogFile)
                If ($PSBoundParameters['Debug']) {
                    ShowLogMessage "OTHER" "`t$($sErrorMessage)`n`t$($sStackTrace)" ([ref]$sLogFile)
                }
            }
        }
        
        # Downloading
        Write-Progress -Activity "Download updated mods..." -PercentComplete $iPercentComplete -Status "Downloading $($PSItem.name)..."
        do {
            ShowLogMessage "INFO" "(Try #$($iNumberDownloadTried)) Downloading the new version of the mod..." ([ref]$sLogFile)
            Try {
                If ($PSItem.sourceWebsite -ne "chocolateminecraft") {
                    Start-BitsTransfer -Source $oModInfo.DownloadUrl -Destination $oModInfo.FilePath -Description "Downloading $($oModInfo.filename)" -ErrorAction Stop
                } Else {
                    Invoke-WebRequest -Uri $oModInfo.DownloadUrl -OutFile $oModInfo.FilePath -Method Post -ErrorAction Stop
                }
                # We change LastWriteTime to today
                ([System.IO.FileInfo]$oModInfo.FilePath).LastWriteTime = Get-Date
                ShowLogMessage "SUCCESS" "The mod has been downloaded successfully!" ([ref]$sLogFile)
            } Catch {
                $sErrorMessage = $PSItem.Exception.Message
                ShowLogMessage "ERROR" "The mod has not been downloaded!" ([ref]$sLogFile)
                If ($PSBoundParameters['Debug']) {
                    ShowLogMessage "DEBUG" "Error detail:" ([ref]$sLogFile)
                    ShowLogMessage "OTHER" "`$($sErrorMessage)" ([ref]$sLogFile)
                }
            }
        } While (-not $bDownloadSuccess -and $iNumberDownloadTried -le $iMaxDownloadTry)

        If (-not $bDownloadSuccess -and $iNumberDownloadTried -gt $iMaxDownloadTry) {
            ShowLogMessage "ERROR" "Too many tries!" ([ref]$sLogFile)
        }
    } ElseIf ($oModInfo.Update -and $NoDownload) {
        ShowLogMessage "DEBUG" "We should download $($oModInfo.DownloadUrl) to $($oModInfo.FilePath)" ([ref]$sLogFile)
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

    ShowLogMessage "OTHER" "" ([ref]$sLogFile)
}
Write-Progress -Activity "Download updated mods ($($iPercentComplete)%)..." -Completed

# Finalizing markdown lines
$aMarkdownModsOptifine += "`t* ``M à J`` : Archive contenant tous les mods"
$aMarkdownModsOptifine += "`t* ``M à J`` : Archive contenant tous les **mods** et toutes les **textures**"
$aMarkdownModsNoOptifine += "`t* ``M à J`` : Archive contenant tous les mods"
$aMarkdownModsNoOptifine += "`t* ``M à J`` : Archive contenant tous les **mods** et toutes les **textures**"

If ($Files) {
    ShowLogMessage "INFO" "Export mods session information to CSV '$($aVersionModsListFile)'" ([ref]$sLogFile)
    Try {
        $aModListDownload | Export-CSV -Path $aVersionModsListFile -Delimiter ";" -Encoding utf8 -NoTypeInformation -ErrorAction Stop
        ShowLogMessage "SUCCESS" "Mods list has been exported successfully!" ([ref]$sLogFile)
    } Catch {
        $sErrorMessage = $_.Exception.Message
        ShowLogMessage "ERROR" "Mods list has not been exported!" ([ref]$sLogFile)
        If ($PSBoundParameters['Debug']) {
            ShowLogMessage "DEBUG" "Error detail:" ([ref]$sLogFile)
            ShowLogMessage "OTHER" "`$($sErrorMessage)" ([ref]$sLogFile)
        }
    }
}

If ($Discord -and $Files) {
    ShowLogMessage "OTHER" "" ([ref]$sLogFile)
    
    ShowLogMessage "INFO" "Export Discord markdown lines to files..." ([ref]$sLogFile)
    $aMarkdownModsOptifine | Out-File -FilePath $sMarkdownOptifine
    $aMarkdownModsNoOptifine | Out-File -FilePath $sMarkdownNoOptifine
}

If ($Website -and $Files) {
    ShowLogMessage "OTHER" "" ([ref]$sLogFile)
    
    ShowLogMessage "INFO" "Export website text lines to files..." ([ref]$sLogFile)
    $aTexteModsOptifine | Out-File -FilePath $sInfoWebSiteOptifine
    $aTexteModsNoOptifine | Out-File -FilePath $sInfoWebSiteNoOptifine
}

ShowLogMessage "OTHER" "" ([ref]$sLogFile)
ShowLogMessage "OTHER" "------------------------------------------------------------" ([ref]$sLogFile)
ShowLogMessage "OTHER" "" ([ref]$sLogFile)

# Show Summary for manual copy
ShowLogMessage "INFO" "Summary:" ([ref]$sLogFile)
ShowLogMessage "OTHER" "`tMods GoC:" ([ref]$sLogFile)
$aModListDownload | Where-Object { $PSItem.Update -eq $True -and $PSItem.Type -eq "Mods" -and $PSItem.InternalCategory -ne "NoOptifine" -and $PSItem.GOC -eq $True } | ForEach-Object {
    ShowLogMessage "OTHER" "`t`t$($PSItem.FileName)" ([ref]$sLogFile)
}

ShowLogMessage "OTHER" "" ([ref]$sLogFile)

ShowLogMessage "OTHER" "`tMods GoC No Optifine:" ([ref]$sLogFile)
$aModListDownload | Where-Object { $PSItem.Update -eq $True -and $PSItem.Type -eq "Mods" -and $PSItem.InternalCategory -eq "NoOptifine" -and $PSItem.GOC -eq $True } | ForEach-Object {
    ShowLogMessage "OTHER" "`t`t$($PSItem.FileName)" ([ref]$sLogFile)
}

ShowLogMessage "OTHER" "" ([ref]$sLogFile)

ShowLogMessage "OTHER" "`tRessources GoC:" ([ref]$sLogFile)
$aModListDownload | Where-Object { $PSItem.Update -eq $True -and $PSItem.Type -eq "Ressources" -and $PSItem.GOC -eq $True } | ForEach-Object {
    ShowLogMessage "OTHER" "`t`t$($PSItem.FileName)" ([ref]$sLogFile)
}

ShowLogMessage "OTHER" "" ([ref]$sLogFile)

ShowLogMessage "OTHER" "`tShaders GoC:" ([ref]$sLogFile)
$aModListDownload | Where-Object { $PSItem.Update -eq $True -and $PSItem.Type -eq "Shaders" -and $PSItem.GOC -eq $True } | ForEach-Object {
    ShowLogMessage "OTHER" "`t`t$($PSItem.FileName)" ([ref]$sLogFile)
}

ShowLogMessage "OTHER" "" ([ref]$sLogFile)
ShowLogMessage "OTHER" "------------------------------------------------------------" ([ref]$sLogFile)
ShowLogMessage "OTHER" "" ([ref]$sLogFile)

## My copy
If ($Copy) {
    ShowLogMessage "INFO" "Copy GoC Mods..." ([ref]$sLogFile)
    $aModListDownload | .\Copy-ToMinecraftInstance.ps1 -InstancePath "E:\Games\Minecraft\#MultiMC\instances\1.19-Opti\.minecraft" -InternalCategoryExclude "NoOptifine" -GoCOnly -Update $bPreviousDownload -LogFile $sLogFile -Debug
    
    ShowLogMessage "OTHER" "" ([ref]$sLogFile)
    
    ShowLogMessage "INFO" "Copy not GoC Mods..." ([ref]$sLogFile)
    $aModListDownload | .\Copy-ToMinecraftInstance.ps1 -InstancePath "E:\Games\Minecraft\#MultiMC\instances\1.19-TestMods\.minecraft" -InternalCategoryExclude "Optifine" -Update $bPreviousDownload -LogFile $sLogFile -Debug
    
    ShowLogMessage "OTHER" "" ([ref]$sLogFile)
}

Write-CenterText "*************************************" $sLogFile
Write-CenterText "*                                   *" $sLogFile
Write-CenterText "*      Download MC $($MCVersion) Mods      *" $sLogFile
Write-CenterText "*             $(Get-Date -Format 'yyyy.MM.dd')            *" $sLogFile
Write-CenterText "*             End $(Get-Date -Format 'HH:mm')             *" $sLogFile
Write-CenterText "*                                   *" $sLogFile
Write-CenterText "*************************************" $sLogFile
