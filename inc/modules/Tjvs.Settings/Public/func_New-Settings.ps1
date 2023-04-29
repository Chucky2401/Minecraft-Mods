Using namespace System.Management.Automation.Host

function New-Settings {
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
            Date Created   : 22/12/2022
            Modify by      : Chucky2401
            Date modified  : 22/12/2022
            Change         : Creation
    #>
    
    #---------------------------------------------------------[Script Parameters]------------------------------------------------------
    
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
    Param (
        [Parameter(Position = 0, Mandatory = $True)]
        [PSObject]$RootPath
    )
    
    #---------------------------------------------------------[Initialisations]--------------------------------------------------------
    
    #Set Error Action to Silently Continue
    $ErrorActionPreference      = "SilentlyContinue"

    If ($PSBoundParameters['Debug']) {
        $DebugPreference = "Continue"
    } Else {
        $DebugPreference = "SilentlyContinue"
    }

    Add-Type -AssemblyName System.Windows.Forms
    
    #-----------------------------------------------------------[Functions]------------------------------------------------------------
        
    #----------------------------------------------------------[Declarations]----------------------------------------------------------

    $oTemplate = $DefaultSettings

    Import-LocalizedData -BindingVariable "MessageNewSet" -BaseDirectory "local" -FileName "New-Settings.psd1"
    
    $aProperties = @(
        [PSCustomObject]@{ Property = "Global" ; SubProperty = "Stats" ; Question = $MessageNewSet.global_Stats },
        [PSCustomObject]@{ Property = "Restic" ; SubProperty = "ManualPassword" ; Question = $MessageNewSet.restic_ManualPassword },
        [PSCustomObject]@{ Property = "Restic" ; SubProperty = "ResticPasswordFile" ; Question = $MessageNewSet.restic_ResticPasswordFile },
        [PSCustomObject]@{ Property = "Restic" ; SubProperty = "RepositoryPath" ; Question = $MessageNewSet.restic_RepositoryPath },
        [PSCustomObject]@{ Property = "Snapshots" ; SubProperty = "ToKeep" ; Question = $MessageNewSet.snapshot_ToKeep }
    )

    #-----------------------------------------------------------[Execution]------------------------------------------------------------
    
    $aProperties | ForEach-Object {
        $sProperty = $PSItem.Property
        $sSubProperty = $PSItem.SubProperty
        $sQuestion = $PSItem.Question

        switch -Regex ($sSubProperty) {
            "Stats" {
                $oYes = New-Object System.Management.Automation.Host.ChoiceDescription $MessageNewSet.labelYes, $MessageNewSet.helpYes
                $oNo = New-Object System.Management.Automation.Host.ChoiceDescription $MessageNewSet.labelNo, $MessageNewSet.helpNo
                $aOptions = [System.Management.Automation.Host.ChoiceDescription[]]($oYes, $oNo)

                $result = $host.ui.PromptForChoice("", $sQuestion, $aOptions, 1)

                switch ($result) {
                    0 { $oTemplate.$sProperty.$sSubProperty = $False }
                    1 { $oTemplate.$sProperty.$sSubProperty = $True }
                }

                break;
            }
            "ManualPassword" {
                $oYes = New-Object System.Management.Automation.Host.ChoiceDescription $MessageNewSet.labelYes, $MessageNewSet.helpYes
                $oNo = New-Object System.Management.Automation.Host.ChoiceDescription $MessageNewSet.labelNo, $MessageNewSet.helpNo
                $aOptions = [System.Management.Automation.Host.ChoiceDescription[]]($oYes, $oNo)

                $result = $host.ui.PromptForChoice("", $sQuestion, $aOptions, 1)

                switch ($result) {
                    0 { $oTemplate.$sProperty.$sSubProperty = $True }
                    1 { $oTemplate.$sProperty.$sSubProperty = $False }
                }

                break;
            }
            "ResticPasswordFile" {
                If ($oTemplate.Restic.ManualPassword) {
                    break;
                }

                $oFileBrowser = New-Object System.Windows.Forms.SaveFileDialog -Property @{
                    InitialDirectory = "$($RootPath)"
                    Title = $sQuestion
                    Filter = "All files (*.*)|*.*"
                }
                $null = $oFileBrowser.ShowDialog()
                $PasswordFile = $oFileBrowser.FileName

                Read-Host -Prompt $MessageNewSet.question_password -AsSecureString | ConvertFrom-SecureString | Out-File $PasswordFile
                $oTemplate.$sProperty.$sSubProperty = $PasswordFile

                break;
            }
            "RepositoryPath" {
                $oFolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
                    InitialDirectory = "$($PSScriptRoot)"
                    Description = $sQuestion
                }
                $null = $oFolderBrowser.ShowDialog()
                $ResticPath = $oFolderBrowser.SelectedPath

                $oTemplate.$sProperty.$sSubProperty = $ResticPath

                break;
            }
            "ToKeep" {
                $bValidNumber = $False
                While (-not $bValidNumber) {
                    $sSnapshotsToKeep = Read-Host -Prompt $sQuestion
                    Try {
                        $iSnapshotsToKeep = $sSnapshotsToKeep.ToInt32($null)
                        $bValidNumber = $True
                    } Catch {
                        Write-Host $MessageNewSet.invalid_nbr -ForegroundColor Red
                    }
                }
                $oTemplate.$sProperty.$sSubProperty = $iSnapshotsToKeep
                
                break;
            }
        }
        ShowMessage "OTHER" ""
    }

    $oTemplate | ConvertTo-Json | Out-File conf\settings.json
}
