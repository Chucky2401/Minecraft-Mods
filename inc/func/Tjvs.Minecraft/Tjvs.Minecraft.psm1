Get-ChildItem (Split-Path $Script:MyInvocation.MyCommand.Path) -Filter 'func_*.ps1' -Recurse | ForEach-Object {
    . $PSItem.FullName
}

Get-ChildItem "$(Split-Path $Script:MyInvocation.MyCommand.Path)\Public\*" -Filter 'func_*.ps1' -Recurse | ForEach-Object {
    Export-ModuleMember -Function ($PSItem.BaseName -Split "_")[1]
}
