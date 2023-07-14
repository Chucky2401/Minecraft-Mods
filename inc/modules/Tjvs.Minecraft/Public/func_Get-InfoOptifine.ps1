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
        [string]$MCVersion
    )

    $sRegexMCVersion  = [Regex]::Escape($MCVersion)
    $sDownloadUrl     = "https://optifine.net/"
    $sPatternOptifine = "^.+href=`"(.+f=((?:preview_)?Optifine_$($sRegexMCVersion)_(.+_.+_(.+))\.jar).+)`">Download<\/a>$"

    $oWebReponse = Invoke-WebRequest https://optifine.net/downloads -SessionVariable oSession -UserAgent "Mozilla/5.0 (Windows NT x.y; Win64; x64; rv:10.0) Gecko/20100101 Firefox/10.0"

    $oDownloadUrl  = @{Label = "DownloadUrl" ; Expression = {(($_.outerHTML | Select-String -Pattern $sPatternOptifine).Matches.Groups[1].Value | Select-String -Pattern "^.+(http://optifine\.net/.+)$").Matches.Groups[1].Value}}
    $oFileName     = @{Label = "FileName" ; Expression = {($_.outerHTML | Select-String -Pattern $sPatternOptifine).Matches.Groups[2].Value}}
    $oVersion      = @{Label = "Version" ; Expression = {($_.outerHTML | Select-String -Pattern $sPatternOptifine).Matches.Groups[3].Value}}
    $oMinorVersion = @{Label = "MinorVersion" ; Expression = {($_.outerHTML | Select-String -Pattern $sPatternOptifine).Matches.Groups[4].Value}}

    $oFirstInfo = $oWebReponse.Links | Where-Object { $PSItem.outerHTML -match $sPatternOptifine } | Select-Object $oDownloadUrl, $oVersion, $oMinorVersion, $oFileName | Sort-Object MinorVersion -Desc | Select-Object -First 1

    If ($null -ne $oFirstInfo) {
        $sFileName        = [Regex]::Escape($oFirstInfo.FileName)
        $sPatternDownload = "^.+'(downloadx\?f=$($sFileName)).+' onclick=.+>Download<\/a>"
    
        $oWebReponse = Invoke-WebRequest $oFirstInfo.DownloadUrl -WebSession $oSession -UserAgent "Mozilla/5.0 (Windows NT x.y; Win64; x64; rv:10.0) Gecko/20100101 Firefox/10.0"
    
        $sDownloadUrl += (($oWebReponse.Links | Where-Object { $PSItem.outerHTML -match $sPatternDownload }).outerHTML | Select-String -Pattern $sPatternDownload).Matches.Groups[1].Value  -replace "downloadx", "download"
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
