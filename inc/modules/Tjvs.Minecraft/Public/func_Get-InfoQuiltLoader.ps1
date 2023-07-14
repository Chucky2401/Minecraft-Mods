function Get-InfoQuiltLoader {
    <#
        .SYNOPSIS
            Retrieve Quilt loader mods information
        .DESCRIPTION
            From the MC Version, query the website https://meta.fabricmc.net to get information on version and download link
        .PARAMETER MCVersion
            Version of Minecraft to query on the website
        .OUTPUTS
            PSCustomObject with all information needed for the main script
        .EXAMPLE
            .\Get-InfoQuiltLoader -MCVersion "1.18.2" -Mod "Xaeros Minimap"
        .NOTES
            Name           : Get-InfoQuiltLoader
            Version        : 1.0.0
            Created by     : Chucky2401
            Date created   : 09/07/2023
            Modified by    : Chucky2401
            Date modified  : 09/07/2023
            Change         : Creation from Get-InfoFabricLoader
    #>
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [string]$MCVersion
    )

    $oResult = Invoke-RestMethod https://maven.quiltmc.org/repository/release/org/quiltmc/hashed/maven-metadata.xml
    $sVersionAvailableStable = $oResult.metadata.versioning.latest

    If ($sVersionAvailableStable -eq $MCVersion) {
        $oResult           = Invoke-RestMethod https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/maven-metadata.xml
        $sVersionInstaller = $oResult.metadata.versioning.latest
        $dateRelease       = [DateTime]::ParseExact($oResult.metadata.versioning.lastUpdated, "yyyyMMddHHmmss", $null)
        
        $oResult        = Invoke-RestMethod https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-loader/maven-metadata.xml
        $sVersionLoader = $oResult.metadata.versioning.latest
        
        $sVersion      = "$($sVersionLoader)($($sVersionInstaller))"
        $sFileName     = "quilt-installer-$($sVersionInstaller).jar"
        $sDownloadLink = "https://maven.quiltmc.org/repository/release/org/quiltmc/quilt-installer/$($sVersionInstaller)/$($sFileName)"
        $fileLength    = (Invoke-WebRequest -Uri $sDownloadLink).RawContentLength
    
        $sId = [String]::Join("", $sVersion.ToCharArray().ToByte($null))
    
        $oInformation = [PSCustomObject]@{
            Version      = $sVersion
            id           = $sId
            filename     = $sFileName
            fileDate     = $dateRelease
            fileLength   = $fileLength
            downloadUrl  = $sDownloadLink
            dependencies = ""
        }
    } Else {
        $oInformation = $null
    }


    return $oInformation
}
