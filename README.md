# Minecraft-Mods
My scripts to download Minecraft mods

![GitHub](https://img.shields.io/github/license/Chucky2401/Minecraft-Mods?style=plastic)

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

You can also use the common parameters of PowerShell (-Debug, -Verbose, etc.).

The Get-Help command works too:
`Get-Help .\Get-ModsNewVersion.ps1`

The script will generate a log file for each run, a csv file with the list of mods and some useful information for the next run or you, a markdown file to post it on Discord (in French only for the moment) and a text file for easy copy'n'paste for a website.

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

        *At the beginning, the script will generate a folder named with the version, and subfolder for Mods, Ressources and Shaders*. See *Appendix I.* for details.

4. Modify or create your file `csv\00_main_listing.csv`. Use the existing one to help yourself

    For the moment, the field **internalCategory** only managed the *NoOptifine* value. I use it myself because I rather use the Sodium mods instead of Optifine. But all the Gentlemen of Craft rather still use OptiFine

5. Run the script in a PowerShell console with at least the version parameter!

#### Examples

1. .\Get-ModsNewVersion.ps1 -MCVersion "1.18.2"

    *Will download all the mods updated for the Minecraft 1.18.2 version*

2. .\Get-ModsNewVersion.ps1 -MCVersion "1.19.0" -NoDowload

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
