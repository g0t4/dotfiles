function Get-AliasByDefinition {

    param (
        [string] $Definition
    )

    Get-Alias -Definition $Definition   
}

set-alias gald "Get-AliasByDefinition"


function _cd_cmd() {
    param([string]$cmd) 
    # change to the directory containing the command
    Get-Command $cmd -All | `
        Select-Object -ExpandProperty Source | `
        Split-Path -Parent | `
        Set-Location
}
set-alias cdcmd _cd_cmd

function _gcm_path() {
    param([string]$cmd) 

    Get-Command $cmd -All | `
        Select-Object -ExpandProperty Source 
}

set-alias gcmp _gcm_path
