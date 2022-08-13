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
    .OUTPUTS
        Log file, markdown file for Gentlemen of Craft Discord server, text file to update the website and a csv with all the mods and information about them.
    .EXAMPLE
        .\Get-ModsNewVersion.ps1 -MCVersion "1.19.0"
    .EXAMPLE
        .\Get-ModsNewVersion.ps1 -MCVersion "1.19.0" -NoDownload
    .NOTES
        Name           : Get-ModsNewVersion
        Version        : 1.0.3
        Created by     : Chucky2401
        Date created   : 13/07/2022
        Modified by    : Chucky2401
        Date modified  : 13/08/2022
        Change         : Fix settings var wrong file
    .LINK
        https://github.com/Chucky2401/Minecraft-Mods/blob/main/README.md#get-modsnewversion
#>

#---------------------------------------------------------[Script Parameters]------------------------------------------------------

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
Param (
    [Parameter(Mandatory)]
    [ValidatePattern("\d+\.\d+\.\d+")]
    [string]$MCVersion,
    [switch]$NoDownload
)

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference      = "SilentlyContinue"
#$ErrorActionPreference      = "Stop"

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
            Date modified  : 02/06/2022
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

    If ($sLogFile.Value.GetType().Name -ne "String") {
        $sLogFile.Value += $sSortie
    } Else {
        Write-Output $sSortie >> $sLogFile.Value
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
        [string]$message
    )

    $sDate = Get-Date -UFormat "%d.%m.%Y - %H:%M:%S"

    switch ($type) {
        "INFO" {
            Write-Host "[$($sDate)] (INFO)    $($message)" -ForegroundColor Cyan
            Break
        }
        "WARNING" {
            Write-Host "[$($sDate)] (WARNING) $($message)" -ForegroundColor White -BackgroundColor Black
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
            Write-Host "[$($sDate)] (DEBUG)   $($message)" -ForegroundColor Cyan -BackgroundColor Black
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
            Date modified  : 02/06/2022
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
            Write-Host $sSortie -ForegroundColor Cyan -BackgroundColor Black
            Break
        }
        "OTHER" {
            $sSortie = "$($message)"
            Write-Host $sSortie
            Break
        }
    }

    If ($sLogFile.Value.GetType().Name -ne "String") {
        $sLogFile.Value += $sSortie
    } Else {
        Write-Output $sSortie >> $sLogFile.Value
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
    $nStringLength    = $sChaine.Length
    $nPaddingSize     = "{0:N0}" -f (($nConsoleWidth - $nStringLength) / 2)
    $nSizePaddingLeft = $nPaddingSize / 1 + $nStringLength
    $sFinalString     = $sChaine.PadLeft($nSizePaddingLeft, " ").PadRight($nSizePaddingLeft, " ")

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
            Get-Settings ".\conf\Clean-Restic.ps1.ini"
        .NOTES
            Name           : Get-Settings
            Created by     : Chucky2401
            Date created   : 08/07/2022
            Modified by    : Chucky2401
            Date modified  : 08/07/2022
            Change         : Creating
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Position=0,Mandatory=$true)]
        [string]$File
    )

    $htSettings = @{}

    Get-Content $File | Where-Object { $PSItem -notmatch "^;|^\[" -and $PSItem -ne "" } | ForEach-Object {
        $aLine = [regex]::Split($PSItem, '=')
        $htSettings.Add($aLine[0].Trim(), $aLine[1].Trim())
    }

    Return $htSettings
}

function Get-InfoOptifine {
    <#
        .SYNOPSIS
            Retrieve Optifine mods information
        .DESCRIPTION
            From the MC Version, query the website https://optifine.net/ to get information on version and download link
        .PARAMETER MCVersion
            Version of Minecraft to query on the website
        .OUTPUTS
            PSCustomObject with all information needed for the main script
        .EXAMPLE
            .\Get-InfoOptifine -MCVersion "1.18.2"
        .NOTES
            Name           : Get-InfoOptifine
            Version        : 1.0.1.1
            Created by     : Chucky2401
            Date created   : 14/07/2022
            Modified by    : Chucky2401
            Date modified  : 19/07/2022
            Change         : Return null object if nothing has been found
    #>
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$MCVersion
    )

    $sRegexMCVersion  = [Regex]::Escape($MCVersion)
    $sDownloadUrl     = "https://optifine.net/"
    $sPatternOptifine = "^.+url=(.+f=(Optifine_$($sRegexMCVersion)_(.+_.+_(.+))\.jar).+)`">Download<\/a>$"

    $oWebReponse = Invoke-WebRequest https://optifine.net/downloads -SessionVariable oSession -UserAgent "Mozilla/5.0 (Windows NT x.y; Win64; x64; rv:10.0) Gecko/20100101 Firefox/10.0"

    $oDownloadUrl  = @{Label = "DownloadUrl" ; Expression = {($_.outerHTML | Select-String -Pattern $sPatternOptifine).Matches.Groups[1].Value}}
    $oFileName     = @{Label = "FileName" ; Expression = {($_.outerHTML | Select-String -Pattern $sPatternOptifine).Matches.Groups[2].Value}}
    $oVersion      = @{Label = "Version" ; Expression = {($_.outerHTML | Select-String -Pattern $sPatternOptifine).Matches.Groups[3].Value}}
    $oMinorVersion = @{Label = "MinorVersion" ; Expression = {($_.outerHTML | Select-String -Pattern $sPatternOptifine).Matches.Groups[4].Value}}

    $oFirstInfo = $oWebReponse.Links | Where-Object { $PSItem.outerHTML -match $sPatternOptifine } | Select-Object $oDownloadUrl, $oVersion, $oMinorVersion, $oFileName | Sort-Object MinorVersion -Desc | Select-Object -First 1

    If ($null -ne $oFirstInfo) {
        $sFileName        = [Regex]::Escape($oFirstInfo.FileName)
        $sPatternDownload = "^.+'(downloadx\?f=$($sFileName).+)' onclick=.+>Download<\/a>"
    
        $oWebReponse = Invoke-WebRequest $oFirstInfo.DownloadUrl -WebSession $oSession -UserAgent "Mozilla/5.0 (Windows NT x.y; Win64; x64; rv:10.0) Gecko/20100101 Firefox/10.0"
    
        $sDownloadUrl += (($oWebReponse.Links | Where-Object { $PSItem.outerHTML -match $sPatternDownload }).outerHTML | Select-String -Pattern $sPatternDownload).Matches.Groups[1].Value
        $fileLength    = (Invoke-WebRequest -Uri $sDownloadUrl -WebSession $oSession).RawContentLength
    
        $htDepend = @{
            modId        = 322385
            relationType = 3
        }
    
        $sId = [String]::Join("", $oFirstInfo.Version.ToCharArray().ToByte($null))
    
        $oInformation = [PSCustomObject]@{
            Version      = $oFirstInfo.Version
            id           = $sId
            filename     = $oFirstInfo.FileName
            fileDate     = Get-Date
            fileLength   = $fileLength
            downloadUrl  = $sDownloadUrl
            dependencies = $htDepend
        }
    } Else {
        $oInformation = $null
    }


    return $oInformation
}

function Get-InfoReplayMod {
    <#
        .SYNOPSIS
            Retrieve ReplayMod mods information
        .DESCRIPTION
            From the MC Version, query the website https://www.replaymod.com/ to get information on version and download link
        .PARAMETER MCVersion
            Version of Minecraft to query on the website
        .OUTPUTS
            PSCustomObject with all information needed for the main script
        .EXAMPLE
            .\Get-InfoReplayMod -MCVersion "1.18.2"
        .NOTES
            Name           : Get-InfoReplayMod
            Version        : 1.0.1.1
            Created by     : Chucky2401
            Date created   : 14/07/2022
            Modified by    : Chucky2401
            Date modified  : 19/07/2022
            Change         : Return null object if nothing has been found
    #>
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$MCVersion
    )

    $sRegexMCVersion  = [Regex]::Escape($MCVersion)
    $sDownloadUrl = "https://www.replaymod.com"
    $sFileName = "replaymod-"
    $sPatternReplayMod = "^.+(\/download\/download_new\.php\?version=($($sRegexMCVersion)-(\d\.\d\.\d))).+>Download<.+<\/a>$"

    $oWebReponse = Invoke-WebRequest https://www.replaymod.com/download/ -SessionVariable oSession -UserAgent "Mozilla/5.0 (Windows NT x.y; Win64; x64; rv:10.0) Gecko/20100101 Firefox/10.0"

    $oDownloadUrl = @{Label = "DownloadUrl" ; Expression = {"$($sDownloadUrl)$(($_.outerHTML | Select-String -Pattern $sPatternReplayMod).Matches.Groups[1].Value)"}}
    $oFileName = @{Label = "FileName" ; Expression = {"$($sFileName)$(($_.outerHTML | Select-String -Pattern $sPatternReplayMod).Matches.Groups[2].Value).jar"}}
    $oVersion = @{Label = "Version" ; Expression = {($_.outerHTML | Select-String -Pattern $sPatternReplayMod).Matches.Groups[3].Value}}

    $oFirstInfo = $oWebReponse.Links | Where-Object { $PSItem.outerHTML -match $sPatternReplayMod } | Select-Object $oDownloadUrl, $oVersion, $oFileName | Sort-Object Version -Desc | Select-Object -First 1

    If ($null -ne $oFirstInfo) {
        $fileLength = (Invoke-WebRequest -Uri $oFirstInfo.DownloadUrl -WebSession $oSession).RawContentLength
    
        $sId = [String]::Join("", $oFirstInfo.Version.ToCharArray().ToByte($null))
    
        $oInformation = [PSCustomObject]@{
            Version      = $oFirstInfo.Version
            id           = $sId
            filename     = $oFirstInfo.FileName
            fileDate     = Get-Date
            fileLength   = $fileLength
            downloadUrl  = $oFirstInfo.DownloadUrl
            dependencies = ""
        }
    } Else {
        $oInformation = $null
    }

    return $oInformation
}

function Get-InfoXaeroMod {
    <#
        .SYNOPSIS
            Retrieve Xaeros mods information (Minimap and Worldmap)
        .DESCRIPTION
            From the MC Version, query the website https://chocolateminecraft.com/ to get information on version and download link
        .PARAMETER MCVersion
            Version of Minecraft to query on the website
        .PARAMETER Mod
            The mod you want to retrieve information ("Xaeros Minimap" or "Xaeros WorldMap")
        .OUTPUTS
            PSCustomObject with all information needed for the main script
        .EXAMPLE
            .\Get-InfoXaeroMod -MCVersion "1.18.2" -Mod "Xaeros Minimap"
        .EXAMPLE
            .\Get-InfoXaeroMod -MCVersion "1.19" -Mod "Xaeros WorldMap"
        .NOTES
            Name           : Get-InfoXaeroMod
            Version        : 1.0.1.1
            Created by     : Chucky2401
            Date created   : 14/07/2022
            Modified by    : Chucky2401
            Date modified  : 19/07/2022
            Change         : Return null object if nothing has been found
    #>
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$MCVersion,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Xaeros Minimap", "Xaeros WorldMap", IgnoreCase = $false)]
        [string]$Mod
    )

    $sRegexMCVersion  = [Regex]::Escape($MCVersion)
    $sPatternXaeros = ""
    $sUrl = ""
    switch ($Mod) {
        "Xaeros Minimap" {
            $sPatternXaeros = "(^https:\/\/.+(Xaeros_.+_((\d+)\.(\d+)\.(\d+))_Fabric_$($sRegexMCVersion)\.jar))$"
            $sUrl = "https://chocolateminecraft.com/minimapdownload.php"
        }
        "Xaeros WorldMap" {
            $sPatternXaeros = "(^https:\/\/.+(XaerosWorldMap_((\d+)\.(\d+)\.(\d+))_Fabric_$($sRegexMCVersion)\.jar))$"
            $sUrl = "https://chocolateminecraft.com/worldmapdownload.php"
        }
        Default {}
    }

    $oWebReponse = Invoke-WebRequest $sUrl -SessionVariable oSession -UserAgent "Mozilla/5.0 (Windows NT x.y; Win64; x64; rv:10.0) Gecko/20100101 Firefox/10.0" -Method Post

    $oDownloadUrl = @{Label = "DownloadUrl" ; Expression = {($_.href | Select-String -Pattern $sPatternXaeros).Matches.Groups[1].Value}}
    $oFileName = @{Label = "FileName" ; Expression = {($_.href | Select-String -Pattern $sPatternXaeros).Matches.Groups[2].Value}}
    $oVersion = @{Label = "Version" ; Expression = {($_.href | Select-String -Pattern $sPatternXaeros).Matches.Groups[3].Value}}
    $oMajorVersion = @{Label = "MajorVersion" ; Expression = {[int]($_.href | Select-String -Pattern $sPatternXaeros).Matches.Groups[4].Value}}
    $oMinorVersion = @{Label = "MinorVersion" ; Expression = {[int]($_.href | Select-String -Pattern $sPatternXaeros).Matches.Groups[5].Value}}
    $oHotFixVersion = @{Label = "HotFixVersion" ; Expression = {[int]($_.href | Select-String -Pattern $sPatternXaeros).Matches.Groups[6].Value}}

    $oFirstInfo = $oWebReponse.Links | Where-Object { $PSItem.href -match $sPatternXaeros } | Select-Object $oDownloadUrl, $oVersion, $oFileName, $oMajorVersion, $oMinorVersion, $oHotFixVersion | Sort-Object -Property @{Expression = "MajorVersion"; Descending = $true}, @{Expression = "MinorVersion"; Descending = $true}, @{Expression = "HotFixVersion"; Descending = $true} | Select-Object -First 1

    If ($null -ne $oFirstInfo) {
        $fileLength = (Invoke-WebRequest -Uri $oFirstInfo.DownloadUrl -WebSession $oSession).RawContentLength
    
        $sId = [String]::Join("", $oFirstInfo.Version.ToCharArray().ToByte($null))
    
        $oInformation = [PSCustomObject]@{
            Version      = $oFirstInfo.Version
            id           = $sId
            filename     = $oFirstInfo.FileName
            fileDate     = Get-Date
            fileLength   = $fileLength
            downloadUrl  = $oFirstInfo.DownloadUrl
            dependencies = ""
        }
    } Else {
        $oInformation = $null
    }

    return $oInformation
}

function Get-InfoFabricLoader {
    <#
        .SYNOPSIS
            Retrieve Fabric loader mods information
        .DESCRIPTION
            From the MC Version, query the website https://meta.fabricmc.net to get information on version and download link
        .PARAMETER MCVersion
            Version of Minecraft to query on the website
        .OUTPUTS
            PSCustomObject with all information needed for the main script
        .EXAMPLE
            .\Get-InfoFabricLoader -MCVersion "1.18.2" -Mod "Xaeros Minimap"
        .NOTES
            Name           : Get-InfoFabricLoader
            Version        : 1.0.1.1
            Created by     : Chucky2401
            Date created   : 14/07/2022
            Modified by    : Chucky2401
            Date modified  : 19/07/2022
            Change         : Return null object if nothing has been found
    #>
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$MCVersion
    )

    $oResult = Invoke-RestMethod https://meta.fabricmc.net/v2/versions/game
    $sVersionAvailableStable = ($oResult | Where-Object { $PSItem.version -eq $MCVersion -and $PSItem.stable -eq "True" }).version

    If ($sVersionAvailableStable -eq $MCVersion) {
        $oResult           = Invoke-RestMethod https://meta.fabricmc.net/v2/versions/installer
        $sVersionInstaller = ($oResult | Where-Object { $PSItem.stable -eq "True" }).version
        $sDownloadLink     = ($oResult | Where-Object { $PSItem.stable -eq "True" }).url
    
        $oResult        = Invoke-RestMethod https://meta.fabricmc.net/v2/versions/loader
        $sVersionLoader = ($oResult | Where-Object { $PSItem.stable -eq "True" }).version
    
        $sVersion   = "$($sVersionLoader)($($sVersionInstaller))"
        $sFileName  = "fabric-installer-$($sVersionInstaller).jar"
        $fileLength = (Invoke-WebRequest -Uri $sDownloadLink).RawContentLength
    
        $sId = [String]::Join("", $sVersion.ToCharArray().ToByte($null))
    
        $oInformation = [PSCustomObject]@{
            Version      = $sVersion
            id           = $sId
            filename     = $sFileName
            fileDate     = Get-Date
            fileLength   = $fileLength
            downloadUrl  = $sDownloadLink
            dependencies = ""
        }
    } Else {
        $oInformation = $null
    }


    return $oInformation
}

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# User settings
$htSettings = Get-Settings "$($PSScriptRoot)\conf\Get-ModsNewVersion.ps1.ini"

# API
$sBaseUri         = "https://api.curseforge.com"
$sBaseModFilesUri = "/v1/mods/{modId}/files"
$oHeadersQuery    = @{
    "Accept"    = "application/json"
    "x-api-key" = $htSettings['Token']
}
$oParametersQueryFiles = @{
    Header      = $oHeadersQuery
    Method      = "GET"
    Uri         = ""
    ContentType = "application/json"
}

#$sBaseModUri      = "/v1/mods/{modId}"
#$oParametersQueryMod = @{
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
$aRelationType            = @(
    'None'
    'Embedded Library'
    'Optional Dependency'
    'Required Dependency'
    'Tool'
    'Incompatible'
    'Include'
)
$aMarkdownModsOptifine    = @()
$aMarkdownModsOptifine   += "Mise à jour de **Nos Ressources Minecraft** - *$($sCurseForgeVersion)* - (__{RECOMMANDATION}__)"
$aMarkdownModsNoOptifine  = @()
$aMarkdownModsNoOptifine += "Mise à jour de **Nos Ressources Minecraft Sans Optifine** - *$($sCurseForgeVersion)* - (__{RECOMMANDATION}__)"
$aTexteModsOptifine       = @()
$aTexteModsNoOptifine     = @()

# Minecraft
$sCurseForgeVersion = ""
If ($MCVersion -match "^(.+)\.0$") {
    $sCurseForgeVersion = $MCVersion -replace "\.0$", ""
} Else {
    $sCurseForgeVersion = $MCVersion
}

$htSettings['McBaseFolder']       += $MCVersion
$aDownloadDirectories              = @{
    BaseFolder              = "$($htSettings['McBaseFolder'])"
    GocFolder               = "$($htSettings['McBaseFolder'])\#GoC"
    GocModsFolder           = "$($htSettings['McBaseFolder'])\#GoC\mods"
    GocModsNoOptifineFolder = "$($htSettings['McBaseFolder'])\#GoC\modsNoOptifine"
    GocReesourcesFolder     = "$($htSettings['McBaseFolder'])\#GoC\ressourcepacks"
    GocShadersFolder        = "$($htSettings['McBaseFolder'])\#GoC\shaders"
    ModsFolder              = "$($htSettings['McBaseFolder'])\Mods"
    ModsNoOptifineFolder    = "$($htSettings['McBaseFolder'])\Mods\NoOptifine"
    RessourcesFolder        = "$($htSettings['McBaseFolder'])\Ressources"
    ShadersFolder           = "$($htSettings['McBaseFolder'])\Shaders"
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
If (!(Test-Path "$($htSettings['McBaseFolder'])")) {
    ShowLogMessage "WARNING" "Folder '$($htSettings['McBaseFolder'])' does not exist !" ([ref]$sLogFile)
    ShowLogMessage "INFO" "Creating the folders..." ([ref]$sLogFile)
    Try {
        $aDownloadDirectories.GetEnumerator() | Sort-Object Name | ForEach-Object {
            New-Item -Path "$($PSItem)" -ItemType Directory -ErrorAction Stop | Out-Null
        }
        ShowLogMessage "SUCCESS" "Folder and subfolders created successfully!" ([ref]$sLogFile)
    } Catch {
        $sErrorMessage = $_.Exception.Message
        ShowLogMessage "ERROR" "Folders has not been created!" ([ref]$sLogFile)
        If ($PSBoundParameters['Debug']) {
            ShowLogMessage "DEBUG" "Error detail:" ([ref]$sLogFile)
            ShowLogMessage "OTHER" "`$($sErrorMessage)" ([ref]$sLogFile)
        }

        exit 0
    }
} Else {
    ShowLogMessage "INFO" "Base folder '$($htSettings['McBaseFolder'])' exists. We check subfolders..." ([ref]$sLogFile)
    $aDownloadDirectories.GetEnumerator() | Sort-Object Name | Select-Object -Skip 1 | ForEach-Object {
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
    $iSkip              = [int]$PSItem.skip
    $sPreviousVersion   = ""
    $sFilePath          = ""
    $sPreviousFileName  = ""
    $aDependencies      = @()
    $bAdd               = $False
    $bPreviousModFound  = $False

    ShowLogMessage "INFO" "Querying last file for $($PSItem.name) (Loader: $($htSettings['ModLoaderType']); MC Version: $($sCurseForgeVersion))..." ([ref]$sLogFile)

    switch ($PSItem.sourceWebsite) {
        "curseforge" {
            If ($sType -eq "Mods") {
                $oParametersQueryFiles.Uri = "$($sBaseUri)$($sBaseModFilesUri.Replace("{modId}", $sModId))?gameVersion=$($sCurseForgeVersion)&modLoaderType=$($htSettings['ModLoaderType'])"
            } Else {
                $oParametersQueryFiles.Uri = "$($sBaseUri)$($sBaseModFilesUri.Replace("{modId}", $sModId))?gameVersion=$($sCurseForgeVersion)"
            }
            $oResult = Invoke-RestMethod @oParametersQueryFiles
            $oFileInfo = $oResult.data | Where-Object { $PSItem.gameVersions -match "$([Regex]::Escape($sCurseForgeVersion))$" } | Sort-Object fileDate -Desc | Select-Object -Skip $iSkip -First 1
        }
        "optifine" {
            $oFileInfo = Get-InfoOptifine -MCVersion $sCurseForgeVersion
        }
        "replaymod" {
            $oFileInfo = Get-InfoReplayMod -MCVersion $sCurseForgeVersion
        }
        "chocolateminecraft" {
            $oFileInfo = Get-InfoXaeroMod -MCVersion $sCurseForgeVersion -Mod $sModName
        }
        "fabricmc" {
            $oFileInfo = Get-InfoFabricLoader -MCVersion $sCurseForgeVersion
        }
        Default { $oFileInfo = $null }
    }

    Write-Progress -Activity "Download updated mods ($($iPercentComplete)%)..." -PercentComplete $iPercentComplete -Status "Checking update for $($PSItem.name)..."
    If ($null -ne $oFileInfo) {
        ShowLogMessage "INFO" "A file has been found!" ([ref]$sLogFile)

        # Format dependencies
        $oFileInfo.dependencies | Where-Object { $PSItem.relationType -match "3|4" } | ForEach-Object {
            $iModId = $PSItem.modId
            $sModName = ($aMainModsList | Where-Object { $PSItem.id -eq $iModId }).displayName
            If ($sModName -eq "" -or $null -eq $sModName) {
                $sModName = "{Unknow_$($iModId)}"
            }
            $sRelation = $aRelationType[$PSItem.relationType]
            $aDependencies += "$($sModName)($($sRelation))"
        }
        $sDependencies = [String]::Join("/", $aDependencies)

        # Get mod version
        If ($sVersionPattern -ne "" -or $null -eq $sVersionPattern) {
            $aMatchesVersion = $oFileInfo.$($sField) | Select-String -Pattern $sVersionPattern
            If ($aMatchesVersion.Length -ge 1) {
                $sVersion = $aMatchesVersion.Matches.Groups[1].Value
            } Else {
                ShowLogMessage "ERROR" "Cannot found version from $($sField) with pattern $($sVersionPattern)!" ([ref]$sLogFile)
                $sVersion = "x.x.x"
            }
        } Else {
            $sVersion = ""
        }

        # Check download URL
        If ($oFileInfo.downloadUrl -eq "" -or $null -eq $oFileInfo.downloadUrl) {
            $sIdFirstPart = ($oFileInfo.id).ToString().Substring(0, 4)
            $sIdSecondPart = ($oFileInfo.id).ToString().Substring(4)
            $oFileInfo.downloadUrl = "https://edge.forgecdn.net/files/$($sIdFirstPart)/$($sIdSecondPart)/$($oFileInfo.fileName)"
        }

        # Mod path for download destination
        switch ($sType) {
            "Mods" {
                If ($sInternalCategory -eq "NoOptifine") {
                    $sFilePath = "$($aDownloadDirectories['ModsNoOptifineFolder'])\$($oFileInfo.filename)"
                } Else {
                    $sFilePath = "$($aDownloadDirectories['ModsFolder'])\$($oFileInfo.filename)"
                }
            }
            "Ressources" {
                $sFilePath = "$($aDownloadDirectories['RessourcesFolder'])\$($oFileInfo.filename)"
            }
            "Shaders" {
                $sFilePath = "$($aDownloadDirectories['ShadersFolder'])\$($oFileInfo.filename)"
            }
            Default {
                $sFilePath = "$($aDownloadDirectories['ModsFolder'])\$($oFileInfo.filename)"
            }
        }

        If (!$bPreviousDownload) {
            ShowLogMessage "INFO" "No previous download. The file will be download anyway." ([ref]$sLogFile)
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
                PrevisouFileName = ""
                FileDate         = $oFileInfo.fileDate
                FileLength       = $oFileInfo.fileLength
                DownloadUrl      = $oFileInfo.downloadUrl
                GameVersion      = $sCurseForgeVersion
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
                        ShowLogMessage "INFO" "The mods has been updated! ($($sPreviousVersion) -> $($sVersion))" ([ref]$sLogFile)
                    } Else {
                        ShowLogMessage "INFO" "The mods has been updated for Minecraft $($sCurseForgeVersion)!" ([ref]$sLogFile)
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
                PrevisouFileName = $sPreviousFileName
                FileDate         = $oFileInfo.fileDate
                FileLength       = $oFileInfo.fileLength
                DownloadUrl      = $oFileInfo.downloadUrl
                GameVersion      = $sCurseForgeVersion
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
            PrevisouFileName = ""
            FileDate         = ""
            FileLength       = ""
            DownloadUrl      = ""
            GameVersion      = ""
            Dependencies     = ""
            Copy             = $bCopy
            Add              = ""
            Update           = ""
        }
    }
    
    If ($oModInfo.Update -and !$NoDownload) {
        # Downloading
        Write-Progress -Activity "Download updated mods..." -PercentComplete $iPercentComplete -Status "Downloading $($PSItem.name)..."
        ShowLogMessage "INFO" "Downloading the new version of the mod..." ([ref]$sLogFile)
        Try {
            If ($PSItem.sourceWebsite -ne "chocolateminecraft") {
                Start-BitsTransfer -Source $oModInfo.DownloadUrl -Destination $oModInfo.FilePath -Description "Downloading $($oModInfo.filename)"
            } Else {
                Invoke-WebRequest -Uri $oModInfo.DownloadUrl -OutFile $oModInfo.FilePath -Method Post
            }
            # We change LastWriteTime to today
            ([System.IO.FileInfo]$oModInfo.FilePath).LastWriteTime = Get-Date
            ShowLogMessage "SUCCESS" "The mod has been downloaded successfully!" ([ref]$sLogFile)
        } Catch {
            $sErrorMessage = $_.Exception.Message
            ShowLogMessage "ERROR" "The mod has not been downloaded!" ([ref]$sLogFile)
            If ($PSBoundParameters['Debug']) {
                ShowLogMessage "DEBUG" "Error detail:" ([ref]$sLogFile)
                ShowLogMessage "OTHER" "`$($sErrorMessage)" ([ref]$sLogFile)
            }
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

ShowLogMessage "OTHER" "" ([ref]$sLogFile)

ShowLogMessage "INFO" "Export Discord markdown lines to files..." ([ref]$sLogFile)
$aMarkdownModsOptifine | Out-File -FilePath $sMarkdownOptifine
$aMarkdownModsNoOptifine | Out-File -FilePath $sMarkdownNoOptifine

ShowLogMessage "OTHER" "" ([ref]$sLogFile)

ShowLogMessage "INFO" "Export website text lines to files..." ([ref]$sLogFile)
$aTexteModsOptifine | Out-File -FilePath $sInfoWebSiteOptifine
$aTexteModsNoOptifine | Out-File -FilePath $sInfoWebSiteNoOptifine

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
$aModListDownload | Where-Object { $PSItem.Update -eq $True -and $PSItem.Type -eq "Ressources" -and $PSItem.GOC -eq $True } |ForEach-Object {
    ShowLogMessage "OTHER" "`t`t$($PSItem.FileName)" ([ref]$sLogFile)
}

ShowLogMessage "OTHER" "" ([ref]$sLogFile)

ShowLogMessage "OTHER" "`tShaders GoC:" ([ref]$sLogFile)
$aModListDownload | Where-Object { $PSItem.Update -eq $True -and $PSItem.Type -eq "Shaders" -and $PSItem.GOC -eq $True } |ForEach-Object {
    ShowLogMessage "OTHER" "`t`t$($PSItem.FileName)" ([ref]$sLogFile)
}

ShowLogMessage "OTHER" "" ([ref]$sLogFile)
ShowLogMessage "OTHER" "------------------------------------------------------------" ([ref]$sLogFile)
ShowLogMessage "OTHER" "" ([ref]$sLogFile)

Write-CenterText "*************************************" $sLogFile
Write-CenterText "*                                   *" $sLogFile
Write-CenterText "*      Download MC $($MCVersion) Mods      *" $sLogFile
Write-CenterText "*             $(Get-Date -Format 'yyyy.MM.dd')            *" $sLogFile
Write-CenterText "*             End $(Get-Date -Format 'HH:mm')             *" $sLogFile
Write-CenterText "*                                   *" $sLogFile
Write-CenterText "*************************************" $sLogFile
