# Minecraft-Mods
My scripts to download Minecraft mods

![GitHub](https://img.shields.io/github/license/Chucky2401/Minecraft-Mods)

## Table of Contents

- [Minecraft-Mods](#minecraft-mods)
  - [Table of Contents](#table-of-contents)
  - [Why this script](#why-this-script)
  - [Description](#description)
  - [Prerequisites](#prerequisites)
    - [Get-ModsNewVersion](#get-modsnewversion)
      - [Parameters](#parameters)
      - [How to use](#how-to-use)
      - [Examples](#examples)
      - [Appendix](#appendix)
        - [I. Folders organization](#i-folders-organization)
        - [II. Main listing fields description](#ii-main-listing-fields-description)
    - [Copy-ToMinecraftInstance](#copy-tominecraftinstance)
      - [Parameters](#parameters-1)
      - [How to use](#how-to-use-1)
      - [Examples](#examples-1)

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
- CopyTo-MinecraftInstance

I plan to do this script (not exhaustive):

- CopyTo-GocFolder

## Prerequisites

This script has only been testing with **[PowerShell Core 7.2.5](https://github.com/PowerShell/PowerShell/releases/tag/v7.2.5)**

### Get-ModsNewVersion

This first script help me to clean check mods update and download if necessary.
It takes **at least the Minecraft Version with 3-digits format** as parameter.

#### Parameters

- **NoDownload** *(switch)*: if you want to run the script without downloading any mods, like a dry run.
- **Discord** *(switch)*: generate markdown files to copy/paste on Discord
- **Website** *(switch)*: generate text files to update the GoC Website
- **Copy** *(switch)*: initiate copy to your instance Minecraft with the script `Copy-ToMinecraftInstance.ps1` (need change, plan :wink:)
- **NoFile** *(switch)*: do not generate any files, except log

You can also use the common parameters of PowerShell (-Debug, -Verbose, etc.).

The Get-Help command works too:
`Get-Help .\Get-ModsNewVersion.ps1`

The script will generate a log file for each run, a csv file with the list of mods and some useful information for the next run or you.
And only with associated parameter markdown files to post it on Discord (in French only for the moment) and text files for easy copy'n'paste for a website.

If you already download mods for the same version of Minecraft, the previous file will be renamed with appending *.old* at the end of the file.

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
    |   |_resourcepacks
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
**Important**: As I am French, the csv file must used semicolon ( ; ) as seperator.

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

- forceMcVersion

    Use if you want to force a specific Minecraft version for a mod.
    Example: for Replay Mod 1.19.2, the authors only append 1.19.1 to file name. So the script will not be able to find it.

- skip

    This field is a little bit complex.
    It's used for the Shield Correction Ressources pack.
    For the regular version, I have to skip the first one, because it's the color version.
    Generally, you just have to put 0.

- versionPattern

    The regex to use to find the version of the mod.

- versionField

    In which field we have to look for the version of the mod

### Copy-ToMinecraftInstance

The purpose of the script is to take all the updated mods from the previous script *(Get-ModsNewVersion)* and copy them to the Minecraft instance folder.
Obviously, the mods are copied to the *mods* folder and ressources packs to the *resourcepacks* folder.

**<span style="color: crimson;">I will implement the use of this script in the Get script in a future release.</span>**

#### Parameters

For this script I set up 2 set name for parameters. I will regroup them

- <span style="text-decoration: underline;">*Common* parameters</span>:
  - **InstancePath**: directory of your Minecraft instance. This folder must contains *mods*, *ressourcepack*, etc. folders
  - **InternalCategoryExclude**: to exclude one or more internal category from the mods list
  - **InternalCategoryInclude**: to include one or more internal category from the mods list. **Advise**: all mods with an empty internal category will not be include!
  - **IncludeBaseMods**: to include mods with an empty internal category when you use the parameter `InternalCategoryInclude`. Useless with the exclude one.
  - **GoCOnly**: to include only the mods where the field GOC is equal to True
  - **Update**: to specify if you copy updated mods or new mods. In case of new mods, the script will emptying folders before copy. By default is equal to $True
- <span style="text-decoration: underline;">*Pipeline* set</span>:
  - **Mods**: an array of mods. The first purpose of this parameter is to call this script directly from **Get-ModsNewVersion** (not implemented yet) with a pipe, or with the parameter following the script.
  - **LogFile**: when I will have implemented to call this script from the get script, it will log all the steps to the same log file.
- <span style="text-decoration: underline;">*File* set</span>:
  - **FromFile**: switch to force the script to use a file. But, the script will ask you which csv file to use. This parameter is optional with the next parameter
  - **CsvFile**: path to the csv file. If you use this parameter, you don't have to use the previous parameter, but you must write the absolute path to the csv file.

#### How to use

Two way for this actually:

First one:

1. Import the CSV file to a variable with `Import-Csv`
2. Pipe this variable: `$Mods | .\Copy-ToMinecraftInstance.ps1`

*You can add `-InstancePath "C:\path\to\mine\Minecraft\.minecraft"`*

Seconde one:

1. Call the script with the `-FromFile` parameter: `.\Copy-ToMinecraftInstance.ps1 -FromFile`

Or

1. Call the script with the `-CsvFile` parameter: `.\Copy-ToMinecraftInstance.ps1 -CsvFile "C:\path\to\the\csv\file\1.19.1_mods.csv"`

*You can also use the parameter `-InstancePath` as above*

#### Examples

1. `$Mods | Copy-ToMinecraftInstance.ps1 -InstancePath $env:APPDATA\.minecraft`

Copy all updated mods to the default instance of Minecraft

2. `$Mods | Copy-ToMinecraftInstance.ps1 -InstancePath $env:APPDATA\.minecraft -InternalCategoryExclude "Optifine"`

Copy all updated mods except one in the internal category *Optifine* to the default instance of Minecraft

3. `Copy-ToMinecraftInstance.ps1 -Mods $Mods -InstancePath $env:APPDATA\.minecraft -InternalCategoryExclude "Optifine","NoOptifine"`

Copy all updated mods except one in the internal category *Optifine* or *NoOptifine* to the default instance of Minecraft

4. `Copy-ToMinecraftInstance.ps1 -CsvFile "E:\Games\Minecraft\#Setup_Minecraft\#Scripts\Minecraft-Mods\csv\MC_1.19.0-2022.08.13_18.56.csv" -InstancePath "E:\Games\Minecraft\#MultiMC\instances\1.19-Opti\.minecraft" -InternalCategoryExclude "NoOptifine" -GoCOnly`

Copy all updated mods from the .csv file, in the specific instance path, where the internal category is not *NoOptifine* and where the field GOC is equal to True
