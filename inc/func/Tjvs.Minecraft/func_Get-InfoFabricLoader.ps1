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
