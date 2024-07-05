# useful to lookup devices
# - then lookup driver version 
# - can update driver version if old
function Get-DeviceByFriendlyName {
    param ( [string] $FuzzyFriendlyNameMatch)
    
    #  (pnp at this time only, all I likely care about)
    Get-PnpDevice -FriendlyName "*$FuzzyFriendlyNameMatch*" `
        | Sort-Object -Property Class `
        | Format-Table -AutoSize -GroupBy Class
}
set-alias gdev "Get-DeviceByFriendlyName"
# gdev ax211
#    maps to:
#    Get-PnpDevice -FriendlyName *ax211*
# ax210 is intel driver for Wi-Fi 6 (IIRC)
# ax211 is intel driver for Wi-Fi 6E card


# meant to match one item
#  - however if match a few or more then group by indicates that
function Get-DeviceProperties {
    param ([string] $FuzzyFriendlyNameMatch)
    Get-PnpDevice -FriendlyName "*$FuzzyFriendlyNameMatch*" `
        | Sort-Object -Property Class `
        | Get-PnpDeviceProperty `
        | Format-Table -GroupBy InstanceId -AutoSize KeyName, Type, Data
}
set-alias gdevp "Get-DeviceProperties"
# gdevp ax211
#  maps to:
#  Get-PnpDevice -FriendlyName *ax211* | Get-PnpDeviceProperty 

function Get-DeviceDriverProperties {
    param ([string] $FuzzyFriendlyNameMatch)
    Get-PnpDevice -FriendlyName "*$FuzzyFriendlyNameMatch*" `
        | Sort-Object -Property Class `
        | Get-PnpDeviceProperty `
        | Where-Object -Property KeyName -Like '*driver*' `
        | Sort-Object -Property InstanceId `
        | Format-Table -GroupBy InstanceId -AutoSize KeyName, Type, Data
}
set-alias gdevd "Get-DeviceDriverProperties"
