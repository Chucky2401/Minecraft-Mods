#Import-LocalizedData -BindingVariable "MessageDefaultSet" -BaseDirectory "local" -FileName "SettingsProperties.psd1"

$DefaultSettings = [PSCustomObject]@{
    general = [PSCustomObject]@{
        modLoaderType = $True
        baseFolder    = ""
    }
    curseforge = [PSCustomObject]@{
        tokenValue   = ""
        urlMod       = "https://api.curseforge.com/v1/mods/{modId}/files?gameVersion={versionMc}&modLoaderType={modLoader}"
        urlResources = "https://api.curseforge.com/v1/mods/{modId}/files?gameVersion={versionMc}"
    }
    minecraft = [PSCustomObject]@{
        baseFolder = ""
    }
    copy = @(
        [PSCustomObject]@{
            includeBaseMods = $True
            gocOnly         = $True
            category        = @("Optifine")
        },
        [PSCustomObject]@{
            includeBaseMods = $True
            gocOnly         = $False
            category        = @("NoOptifine")
        }
    )
}
