function Get-InfoFromCurseForge {
    <#
        .SYNOPSIS
            Get mods from Curseforge
        .DESCRIPTION
            Get mods information from Curseforge and return an object with useful information
        .PARAMETER ModId
            Id of the mod
        .PARAMETER Skip
            Number of line in the response to skip
        .PARAMETER VersionPattern
            Regex pattern to get the version of the mod
        .PARAMETER FieldVersion
            Field to extract version number
        .PARAMETER MCVersion
            Version of Minecraft
        .PARAMETER MainModList
            Mods list
        .PARAMETER Resources
            Switch to indicate we will get a resources pack instead of a mods
        .OUTPUTS
            Object
        .EXAMPLE
            Get-InfoFromCruseForge -ModId 248787 -VersionPattern "(\d+\.\d+\.\d+)\.[a-z]{3}$" -FieldVersion "filename" -MCVersion 1.19.4 -MainModList $modsList

            Get Appleskin (Id: 248787) mod information for Minecraft 1.19.4
        .NOTES
            Name           : Get-InfoFromCurseForge
            Version        : 1.0
            Created by     : Chucky2401
            Date Created   : 29/04/2023
            Modify by      : Chucky2401
            Date modified  : 29/04/2023
            Change         : Creation
        .LINK
            http://github.com/UserName/RepoName
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)]
        [String]$ModId,
        [Parameter(Mandatory = $True)]
        [Int]$Skip,
        [Parameter(Mandatory = $True)]
        [String]$VersionPattern,
        [Parameter(Mandatory = $True)]
        [String]$FieldVersion,
        [Parameter(Mandatory = $True)]
        [String]$MCVersion,
        [Parameter(Mandatory = $True)]
        [Object[]]$MainModList,
        [Parameter(Mandatory = $False)]
        [Switch]$Resources
    )

    $url = $Global:settings.curseforge.urlMod -replace "{modId}", $ModId -replace "{versionMc}", $MCVersion
    If ($Resources) {
        $url = $Global:settings.curseforge.urlResources -replace "{modId}", $ModId -replace "{versionMc}", $MCVersion
    }

    $oHeadersQuery    = @{
        "Accept"    = "application/json"
        "x-api-key" = $global:settings.curseforge.tokenValue
    }
    $oParametersQueryFiles = @{
        Header      = $oHeadersQuery
        Method      = "GET"
        Uri         = $url
        ContentType = "application/json"
    }

    $sDependencies = ""
    $aDependencies = @()
    $aRelationType = @(
        'None'
        'Embedded Library'
        'Optional Dependency'
        'Required Dependency'
        'Tool'
        'Incompatible'
        'Include'
    )
    $oResult      = $null
    $increment    = 0
    $numberLoader = (($global:settings.general.modLoaderType).Count)
    $sVersion     = ""


    do {
        If (-not $Resources) {
            $oParametersQueryFiles.Uri = $Global:settings.curseforge.urlMod -replace "{modId}", $ModId -replace "{versionMc}", $MCVersion -replace "{modLoader}", $global:settings.general.modLoaderType[$increment]
        }

        $oResult = Invoke-RestMethod @oParametersQueryFiles
        $increment++
    } while ($oResult.pagination.resultCount -eq 0 -and $increment -lt $numberLoader)

    If ($oResult.pagination.resultCount -eq 0) {
        return $null
    }

    $oFileInfo = $oResult.data | Where-Object { $PSItem.gameVersions -match "$([Regex]::Escape($MCVersion))$" } | Sort-Object fileDate -Desc | Select-Object -Skip $iSkip -First 1

    $oFileInfo.dependencies | Where-Object { $PSItem.relationType -match "3|4" } | ForEach-Object {
        $iModId = $PSItem.modId
        $sModName = ($MainModList | Where-Object { $PSItem.id -eq $iModId }).displayName
        If ($sModName -eq "" -or $null -eq $sModName) {
            $sModName = "{Unknow_$($iModId)}"
        }
        $sRelation = $aRelationType[$PSItem.relationType]
        $aDependencies += "$($sModName)($($sRelation))"
    }
    $sDependencies = [String]::Join("/", $aDependencies)

    If ($VersionPattern -ne "" -or $null -eq $VersionPattern) {
        $aMatchesVersion = $oFileInfo.$($FieldVersion) | Select-String -Pattern $VersionPattern
        If ($aMatchesVersion.Length -ge 1) {
            $sVersion = $aMatchesVersion.Matches.Groups[1].Value
        } Else {
            #ShowLogMessage -type "ERROR" -message "Cannot found version from $($FieldVersion) with pattern $($VersionPattern)!" -sLogFile ([ref]$sLogFile)
            $sVersion = "x.x.x"
        }
    }

    If ($oFileInfo.downloadUrl -eq "" -or $null -eq $oFileInfo.downloadUrl) {
        $sIdFirstPart = ($oFileInfo.id).ToString().Substring(0, 4)
        $sIdSecondPart = ($oFileInfo.id).ToString().Substring(4)
        $oFileInfo.downloadUrl = "https://edge.forgecdn.net/files/$($sIdFirstPart)/$($sIdSecondPart)/$($oFileInfo.fileName)"
    }

    $oInformation = [PSCustomObject]@{
        Version      = $sVersion
        id           = $oFileInfo.id
        filename     = $oFileInfo.filename
        fileDate     = $oFileInfo.fileDate
        fileLength   = $oFileInfo.fileLength
        downloadUrl  = $oFileInfo.downloadUrl
        dependencies = $sDependencies
    }

    return $oInformation
}
