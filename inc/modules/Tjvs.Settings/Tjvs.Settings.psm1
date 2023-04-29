Get-ChildItem (Split-Path $Script:MyInvocation.MyCommand.Path) -Filter 'func_*.ps1' -Recurse | ForEach-Object {
    . $PSItem.FullName
}

Get-ChildItem "$(Split-Path $Script:MyInvocation.MyCommand.Path)\Public\*" -Filter 'func_*.ps1' -Recurse | ForEach-Object {
    Export-ModuleMember -Function ($PSItem.BaseName -Split "_")[1]
}

Get-ChildItem (Split-Path $Script:MyInvocation.MyCommand.Path) -Filter 'var_*.ps1' -Recurse | ForEach-Object {
    . $PSItem.FullName
}

Get-ChildItem "$(Split-Path $Script:MyInvocation.MyCommand.Path)\Public\*" -Filter 'var_*.ps1' -Recurse | ForEach-Object {
    Export-ModuleMember -Variable ($PSItem.BaseName -Split "_")[1]
}
