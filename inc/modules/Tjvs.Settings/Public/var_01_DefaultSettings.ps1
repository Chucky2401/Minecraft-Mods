#Import-LocalizedData -BindingVariable "MessageDefaultSet" -BaseDirectory "local" -FileName "SettingsProperties.psd1"

$DefaultSettings = [PSCustomObject]@{
    general = [PSCustomObject]@{
        modLoaderType = @("Fabric")
        baseFolder    = ""
    }
    curseforge = [PSCustomObject]@{
        tokenValue   = ""
        urlMod       = "https://api.curseforge.com/v1/mods/{modId}/files?gameVersion={versionMc}&modLoaderType={modLoader}"
        urlResources = "https://api.curseforge.com/v1/mods/{modId}/files?gameVersion={versionMc}"
    }
    modrinth = [PSCustomObject]@{
        urlMod       = "https://api.modrinth.com/v2/project/{modId}/version?game_versions=[`"{versionMc}`"]&loaders=[`"{modLoader}`"]"
        urlResources = "https://api.modrinth.com/v2/project/{modId}/version?game_versions=[`"{versionMc}`"]"
    }
    minecraft = [PSCustomObject]@{
        baseFolder = ""
    }
    copy = @(
        [PSCustomObject]@{
            instancePath    = ""
            includeBaseMods = $True
            gocOnly         = $True
            categoryExclude = @("Optifine")
        },
        [PSCustomObject]@{
            instancePath    = ""
            includeBaseMods = $True
            gocOnly         = $False
            categoryExclude = @("NoOptifine")
        }
    )
}
