# Changelog

## 2022.08.14 - v1.0.4

### Fix

- Typing error for the csv fields *PreviousFileName*
- Wrong mods display in the progress bar

---

## 2022.08.14 - v1.0.3

### New

- Previsous downloaded files are renamed before download with appending **.old** at the end of file (*ie*: *appleskin-fabric-mc1.19-2.4.0.jar* **-->** *appleskin-fabric-mc1.19-2.4.0.jar.old*)
- Two new parameters:
  - *-Discord*: generate markdown file to copy/paste to Discord
  - *-Website*: generate text file to update the Website
    *These were added because they are useful for me only (?)*

## Change

- In the settings file, the string parameter must be surrounded with double quote (")
- 'DEBUG' message are displayed if you use the parameter '-Debug'

### Fix

- Wrong setting file name
- Wrong variable usage with the hashtable folders

---

## 2022.07.21 - v1.0.2

### Fix

- Used a fix value for the Minecraft version in the base folder

---

## 2022.07.21 - v1.0.1

### Change

- Update `README.md` to describe each field of the main list of mods

---

## 2022.07.19

### New

- `Get-ModsNewVersion` script
- README
- CHANGELOG
