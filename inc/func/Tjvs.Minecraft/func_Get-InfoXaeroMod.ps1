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
            Version        : 1.0.1
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
