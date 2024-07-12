
function wcl() {

  $_python = "${WESCONFIG_DOTFILES}\.venv\Scripts\python.exe"
  $_wcl_py = "${WESCONFIG_DOTFILES}\zsh\compat_fish\pythons\wcl.py"
  & $_python $_wcl_py $args

}

function z_pwsh_impl {
  # TODO add z_pwsh_impl such that it wraps z command... right now z command (not this one) takes precedence so this doesn't plugin ... and I wanna wait before I fix that... to see if I feel a need for this again in pwsh...
  # FYI mostly working, but FYI this only detects a github.com URL repo format, not yet using org/repo alone...

  # TLDR = wcl + z
  # FYI still uses z fish completions (b/c same name)

  if ($args -match "github.com") {
    # if a repo url then clone and/or cd to it

    # assume all args are compat w/ wcl (i.e. --dry-run)
    $_path = wcl --path-only @args

    if (Test-Path $_path) {
      # PRN wcl anyways to get latest?
      Set-Location $_path
    }
    else {
      wcl @args
      Set-Location $_path
    }
  }
  else {
    # call z and pass (spread) same args:
    z @args
  }

}


# pipeline expanding aliases:
ealias pbat '| bat -l' -Anywhere
ealias pgr '| sls' -Anywhere
ealias phelp '| bat -l help' -Anywhere
ealias pini '| bat -pl ini' -Anywhere
ealias pjq '| jq .' -Anywhere # shortened
ealias pmd '| bat -l md' # shortened
ealias prb '| bat -pl rb' -Anywhere
ealias psh '| bat -pl sh' -Anywhere
ealias pxml '| bat -l xml' -Anywhere # shortened
ealias pyml '| bat -l yml' -Anywhere # shortened
ealias hC '| hexdump -C' -Anywhere
# todo more in fish's misc for kubectl command



# powershell alias helpers
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
