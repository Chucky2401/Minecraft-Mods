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
