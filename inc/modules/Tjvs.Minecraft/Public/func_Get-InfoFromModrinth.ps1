function Get-InfoFromModrinth {
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
            Get-InfoFromCruseForge -ModId lhGA9TYQ -VersionPattern "(\d+\.\d+\.\d+)\.[a-z]{3}$" -FieldVersion "version_number" -MCVersion 1.19.4 -MainModList $modsList

            Get Appleskin (Id: lhGA9TYQ) mod information for Minecraft 1.19.4
        .NOTES
            Name           : Get-InfoFromModrinth
            Version        : 1.0
            Created by     : Chucky2401
            Date Created   : 30/04/2023
            Modify by      : Chucky2401
            Date modified  : 30/04/2023
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

    $url = $Global:settings.modrinth.urlMod -replace "{modId}", $ModId -replace "{versionMc}", $MCVersion -replace "{modLoader}", ($global:settings.general.modLoaderType).ToLower()
    If ($Resources) {
        $url = $Global:settings.modrinth.urlResources -replace "{modId}", $ModId -replace "{versionMc}", $MCVersion
    }

    $oParametersQueryFiles = @{
        Method      = "GET"
        Uri         = $url
        ContentType = "application/json"
    }

    $sDependencies = ""
    $aDependencies = @()

    $sVersion = ""

    $oResult = Invoke-RestMethod @oParametersQueryFiles
    If ($oResult.Count -eq 0) {
        return $null
    }

    $oFileInfo = $oResult | Where-Object { $PSItem.game_versions -match "$([Regex]::Escape($MCVersion))$" } | Sort-Object date_published -Desc | Select-Object -Skip $iSkip -First 1

    $oFileInfo.dependencies | Where-Object { $PSItem.dependency_type -eq "required" } | ForEach-Object {
        $iModId = $PSItem.project_id
        $sModName = ($MainModList | Where-Object { $PSItem.id -eq $iModId }).displayName
        If ($sModName -eq "" -or $null -eq $sModName) {
            $sModName = "{Unknow_$($iModId)}"
        }
        $sRelation = $PSItem.dependency_type
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

    If ($oFileInfo.files.Count -gt 1) {
        $oFileInfo.files = $oFileInfo.files | Where-Object { $PSItem.primary -eq $True }
    }

    If ($oFileInfo.files.url -eq "" -or $null -eq $oFileInfo.files.url) {
        $projectId = $oFileInfo.project_id
        $fileModId = $oFileInfo.id
        $fileName = $oFileInfo.files.filename
        $oFileInfo.files.url = "https://cdn.modrinth.com/data/$($projectId)/versions/$($fileModId)/$($fileName)"
    }

    $oInformation = [PSCustomObject]@{
        Version      = $sVersion
        id           = $oFileInfo.project_id
        filename     = $oFileInfo.files.filename
        fileDate     = $oFileInfo.date_published
        fileLength   = $oFileInfo.files.size
        downloadUrl  = $oFileInfo.files.url
        dependencies = $sDependencies
    }

    return $oInformation
}
