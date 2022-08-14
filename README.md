# Minecraft-Mods
My scripts to download Minecraft mods

![GitHub](https://img.shields.io/github/license/Chucky2401/Minecraft-Mods)

## Table of Contents

- [Minecraft-Mods](#minecraft-mods)
  - [Table of Contents](#table-of-contents)
  - [Why this script](#why-this-script)
  - [Description](#description)
    - [Get-ModsNewVersion](#get-modsnewversion)
      - [Prerequisites](#prerequisites)
      - [How to use](#how-to-use)
      - [Examples](#examples)
      - [Appendix](#appendix)
        - [I. Folders organization](#i-folders-organization)
        - [II. Main listing fields description](#ii-main-listing-fields-description)

## Why this script

For the label Gentlemen of Craft, I manage to list all the mods we use and pack them.
I inform everybody on the Discord server and our website for the public.
As I don't received any notifications from CurseForge anymore, that took me a long time to check every mod one-by-one to know if an update exist.
So, I decided to use the API to check them.
For some mods (ie: OptiFine, ReplayMod), I parse myself the website where the mods are shared.
By the way, this script help me by generating the markdown text to post it on the Discord Server and generate txt file to help me to update our website.

## Description

I will describe each scripts.
At the moment, there is this script available only:

- Get-ModsNewVersion

I plan to do this script (not exhaustive):

- CopyTo-MinecraftInstance
- CopyTo-GocFolder

### Get-ModsNewVersion

This first script help me to clean check mods update and download if necessary.
It takes **at least the Minecraft Version with 3-digits format** as parameter.
You have one more optional parameters:

- **NoDownload** *(switch)*: if you want to run the script without downloading any mods, like a dry run.
- **Discord** *(switch)*: generate markdown files to copy/paste on Discord
- **Website** *(switch)*: generate text files to update the GoC Website

You can also use the common parameters of PowerShell (-Debug, -Verbose, etc.).

The Get-Help command works too:
`Get-Help .\Get-ModsNewVersion.ps1`

The script will generate a log file for each run, a csv file with the list of mods and some useful information for the next run or you.
And only with associated parameter markdown files to post it on Discord (in French only for the moment) and text files for easy copy'n'paste for a website.

If you already download mods for the same version of Minecraft, the previous file will be renamed with appending *.old* at the end of the file.

#### Prerequisites

This script has only been testing with **[PowerShell Core 7.2.5](https://github.com/PowerShell/PowerShell/releases/tag/v7.2.5)**

#### How to use

The most important part of this Readme!

1. Download all the files and folders and put it in folder of your choice
2. Generate an API key on [CurseForge Console](https://console.curseforge.com/#/), you will have to create an account if you don't have it yet
3. Open the file `conf\Get-ModsNewVersion.ps1.ini` and edit the variable as needed for you :
    1. Token: the token you generated above. Don't try with the one in the file, it will not work!
    2. ModLoaderType: if you want to download the mod for a specific loader (eg: Fabric, Forge, Quilt)
    3. McBaseFolder: the base folder where the script will download all files.

        **All this parameters must be surrounded with double quote mark**

        *At the beginning, the script will generate a folder named with the version, and subfolder for Mods, Ressources and Shaders*. See *[Appendix I.](#i-folders-organization)* for more details.

4. Modify or create your file `csv\00_main_listing.csv`. Use the existing one to help yourself

    For the moment, the field **internalCategory** only managed the *NoOptifine* value. I use it myself because I rather use the Sodium mods instead of Optifine. But all the Gentlemen of Craft rather still use OptiFine. See *[Appendix II.](#ii-main-listing-fields-description)* for more details.

5. Run the script in a PowerShell console with at least the version parameter!

#### Examples

1. .\Get-ModsNewVersion.ps1 -MCVersion "1.18.2"

    *Will download all the mods updated for the Minecraft 1.18.2 version*

2. .\Get-ModsNewVersion.ps1 -MCVersion "1.19.0" -NoDownload

    *Will check the mods update but without download anything*

#### Appendix

##### I. Folders organization

Here an example of the folders and subfolders created at the beginning of the script:

```text
YourBaseFolder
    |_#GoC
    |   |_mods
    |   |_modsNoOptifine
    |   |_ressourcepacks
    |   |_shaders
    |
    |_Mods
    |    |_NoOptifine
    |
    |_Ressources
    |_Shaders
```

##### II. Main listing fields description

I will try to describe you the fields of the main listing csv file.

- name

    The name of the mods displayed on CurseForge.
    For the Optifine, ReplayMod, Fabric Loader and Xaero's mod, write what you want.

- displayName

    The name you want to see in the final csv, or markdown and text file
    For example, for the mods **Roughly Enough Items Fabric/Forge (REI)** I prefere to see **Roughly Enough Items**

- id

    The mod id on CurseForge.
    For the Optifine, ReplayMod, Fabric Loader and Xaero's mod, I converted the mod name into a byte value of each character with this command: `[String]::Join("", "OptiFine".ToCharArray().ToByte($null))`

- type

    Supported values:
    - Mods
    - Ressources
    - Shaders

    Nothing to add more

- summary

    Summary of the mods. Useless in the script, just for me, for reminder.

- sourceWebsite

    The source website of the mod. Use to choose how to retrieve information of the mod.
    Supported values:

    - curseforge
    - optifine
    - replaymod
    - chocolateminecraft
    - fabricmc

- pageLink

    Link to the mod

- internalCategory

    **Only for Mods type**
    I use this field to classified mod between Optifine and sodium mods. Because, as you know, we can't use OptiFine and Sodium together. So for all the Sodium mods, I use the internal category *NoOptifine*. **This is the only supported category at the moment.**
    I think you can leave it empty for your usage.

- goc

    As I download mods for the Gentlemen of Craft and myself, I don't post update of mods don't used by them. So, I use this boolean to help me.
    Moreover, if the value is `True`, the mod will appear in the text and markdown file. Otherwise, it will not. If you don't need the markdown and the text file, just write `False` for each mods. Simple as that!

- copy

    *Not used for the moment*
    This field will help me to know if we have to copy the mod to the `mods` folder.

- skip

    This field is a little bit complex.
    It's used for the Shield Correction Ressources pack.
    For the regular version, I have to skip the first one, because it's the color version.
    Generally, you just have to put 0.

- versionPattern

    The regex to use to find the version of the mod.

- versionField

    In which field we have to look for the version of the mod
