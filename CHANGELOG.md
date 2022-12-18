# Changelog

## 2022.12.18

### Common

#### Change

- Use modules instead of functions directly write in scripts

### Get-ModsNewVersion

#### New

- Add `-Nofile` and `-Copy` parameters
  - `-Nofile`: to not generate any files, except logs
  - `-Copy`: to initiate copy to Minecraft instance with `Copy-ToMinecraftInstance.ps1`
- For the download part, add up to 3 tries.
  I will add this part in the setting file. But I have another feature for this part

#### Change

- Simplified folders creation and use two hash table different

#### Fix

- Typo
- Missing 'ressource' replaced by 'resource'

### Copy-ToMinecraftInstance

#### New

- Add `-InternalCategoryInclude` and `-IncludeBaseMods` parameters
  - `InternalCategoryInclude`: array of *internalCategory* to include for the copy.
    **Advise**: this will not include any mods with an empty *internalCategory*! Read the next information
  - `-IncludeBaseMods`: include all base mods (with an empty *internalCategory*) for the copy. Useless with the parameter `-InternalCategoryExclude`, but useful in combination with `-InternalCategoryInclude`

> These two parameters will be very useful with the next feature on the setting file

#### Change

- Unify version number with the other script

### Log

- *7d77fc5*: feat: MAJOR FEAT: Use modules instead of local functions
- *44def94*: chore: Set regex for Shaders as is now working! Use a conditional regex for CraftPresence

---
## 2022.09.01

### Common

#### Fix

- Fix CraftPresence regex Version for certain version that contain *universal* before file extension.

### Get-ModsNewVersion - v1.2

#### Change

- Add field **ForceMcVersion** for mods. Sometimes, like *Replay Mod*, the author mark the mod compatible for Minecraft 1.19.1 and 1.19.2, but nothing on the website indicate 1.19.2 and only 1.19.1. Or, on CurseForge, the filename indicate both version, but the mods is not tagged compatible. This is a workaround for this.
- Use the new parameter for **Copy-ToMinecraftInstance**

### Copy-ToMinecraftInstance - 1.0.0

#### Change

- Add *Update* (Boolean) parameter. If this parameter is set to $False, the *mods* and *resourcepacks* folders are emptying at the start of the script.

---

## 2022.08.15

### Common

#### Change

*Get-Settings*

- Can pass a starting/ending block to select only few settings and not everything

### Get-ModsNewVersion - v1.1

#### Fix

- If the base folder (*ie: 1.19.1*) does not exist an exception is throw when the script try to create the folder

#### Change

- If the mods cannot be found on the website, the value of **Add** and **Update** are set to *$False* instead of *an empty string*

### Copy-ToMinecraftInstance - v1.0.beta.1

#### New

- Define all parameters and parameter sets

  - The mods information can be passed as an array from pipeline or as a parameter with `-Mods`
  - You can use :
    - `-FromFile` parameter instead and the script will ask you a CSV file
    - If you use the parameter `-CsvFile "C:\Path\to\the\file\myfile.csv"`, no need to add the `-FromFile` and you will not have to choose the file
  - You can add with the parameter `-InstancePath` the path to your Minecraft instance, or the script will ask you
  - Parameter `-GoCOnly` switch to choose the mods only GoC approved

- Rename the previous file name with adding *.disabled* to the end
- Copy the new mod version

---

## Get-ModsNewVersion

### 2022.08.14 - v1.0.4

#### Fix

- Typing error for the csv fields *PreviousFileName*
- Wrong mods display in the progress bar

---

## Get-ModsNewVersion

### 2022.08.14 - v1.0.3

#### New

- Previsous downloaded files are renamed before download with appending **.old** at the end of file (*ie*: *appleskin-fabric-mc1.19-2.4.0.jar* **-->** *appleskin-fabric-mc1.19-2.4.0.jar.old*)
- Two new parameters:
  - *-Discord*: generate markdown file to copy/paste to Discord
  - *-Website*: generate text file to update the Website
    *These were added because they are useful for me only (?)*

## Get-ModsNewVersion

### Change

- In the settings file, the string parameter must be surrounded with double quote (")
- 'DEBUG' message are displayed if you use the parameter '-Debug'

#### Fix

- Wrong setting file name
- Wrong variable usage with the hashtable folders

---

## Get-ModsNewVersion

### 2022.07.21 - v1.0.2

#### Fix

- Used a fix value for the Minecraft version in the base folder

---

## Get-ModsNewVersion

### 2022.07.21 - v1.0.1

#### Change

- Update `README.md` to describe each field of the main list of mods

---

## Get-ModsNewVersion

### 2022.07.19

#### New

- `Get-ModsNewVersion` script
- README
- CHANGELOG
