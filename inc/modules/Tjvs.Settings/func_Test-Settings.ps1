function Test-Settings {
    <#
        .SYNOPSIS
            Summary of the script
        .DESCRIPTION
            Script description
        .PARAMETER param1
            Parameter description
        .INPUTS
            Pipeline input data
        .OUTPUTS
            Output data
        .EXAMPLE
            .\template.ps1 param1
        .NOTES
            Name           : Script-Name
            Version        : 1.0.0
            Created by     : Chucky2401
            Date Created   : 24/12/2022
            Modify by      : Chucky2401
            Date modified  : 24/12/2022
            Change         : Creation
    #>
    
    #---------------------------------------------------------[Script Parameters]------------------------------------------------------
    
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
    Param (
        [Parameter(Position = 0, Mandatory = $False)]
        [PSObject]$Settings
    )
    
    #---------------------------------------------------------[Initialisations]--------------------------------------------------------
    
    #Set Error Action to Silently Continue
    $ErrorActionPreference      = "SilentlyContinue"

    If ($PSBoundParameters['Debug']) {
        $DebugPreference = "Continue"
    } Else {
        $DebugPreference = "SilentlyContinue"
    }
    
    #-----------------------------------------------------------[Functions]------------------------------------------------------------

    function Get-ObjectProperties {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
            [PSObject]$Object,
            [Parameter(Mandatory = $False)]
            [Int32]$Level = 0,
            [Parameter(Mandatory = $False)]
            [String]$Parent = ""
        )
    
        $Tabulation = ""
        $FullPath = ""
        $PropertiesFullPath = @()
    
        for ($i = 0 ; $i -lt $Level ; $i++) {
            $Tabulation += "`t"
        }
    
        If ($Parent -ne "") {
            $FullPath = "$($Parent)."
        }
    
        $Object | Get-Member -MemberType NoteProperty | Sort-Object -Property Name | ForEach-Object {
            If ($PSItem.Definition -match 'PSCustomObject') {
                #Write-Host "$($Tabulation)$($PSItem.Name)"
                [String[]]$PropertiesFullPath += Get-ObjectProperties -Object $($Object.$($PSItem.Name)) -Level $($Level+1) -Parent $($PSItem.Name)
            } Else {
                #Write-Host "$($Tabulation)$($PSItem.Name) Value: $($Object.$($PSItem.Name))"
                $PropertiesFullPath += "$($FullPath)$($PSItem.Name)"
            }
        }
    
        Return [String[]]$PropertiesFullPath
    }
    
    #----------------------------------------------------------[Declarations]----------------------------------------------------------
    
    $bValidSettings = $True

    $aTemplateProperties = $DefaultSettings | Get-ObjectProperties | Where-Object { $PSItem -notmatch "^__|\.__" }
    $aProperties = $Settings | Get-ObjectProperties | Where-Object { $PSItem -notmatch "^__|\.__" }
    
    #-----------------------------------------------------------[Execution]------------------------------------------------------------
    
    $aMissingSettings = Compare-Object -ReferenceObject $aTemplateProperties -DifferenceObject $aProperties | Where-Object { $PSItem.SideIndicator -eq "<=" } `
    | Measure-Object

    If ([String[]]$aMissingSettings.Count -gt 0) {
        $bValidSettings = $False
    }

    Return $bValidSettings
}
