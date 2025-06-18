
function wcl() {

  $_python = "${WES_DOTFILES}\.venv\Scripts\python.exe"
  $_wcl_py = "${WES_DOTFILES}\zsh\compat_fish\pythons\wcl.py"
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
ealias pcp '| Set-Clipboard' -Anywhere # copy to clipboard
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




# *** clipboard helpers
# make it appear as if pbcopy/paste are available
# assumption: this only runs on windows+pwsh
ealias pbcopy "Set-Clipboard" # macos equiv
ealias pbpaste "Get-Clipboard" # macos equiv
ealias pwdcp "pwd | Set-Clipboard" # expand to pwsh equivalent
ealias wdcp "pwd | Set-Clipboard" # expand to pwsh equivalent
# FYI look at clipcopy/paste in omz, or fish_*_copy/paste for how other tools wrap system specific backends (ie to make pbcopy/paste an entrypoint in pwsh+win)




# *** dir helpers
# ealias .. 'cd ../'
# ealias ... 'cd ../../'
# etc
for ($i = 2; $i -le 9; $i++) {
  $name = '.' * $i
  $iminus1 = $i - 1
  $value = '../' * $iminus1
  ealias "$name" "cd $value"
}

function tree() {
  # choco install tree --yes

  tree.exe -I 'node_modules|bower_components|.git' `
      -A --noreport --dirsfirst $args

  # func b/c need to pass args & compose into further aliases below (those can expand)
  # -A ansi style level lines - looks clean!
  # -F (trailing / * etc like ls)
  # -I are ignored directories (even if use -a for all files, still ignores -I stuffs which is what I want)
  # --noreport : no summary/count of dirs/files
}
ealias treea "tree -a" # all files (minus of course -I ignores)
ealias treed "tree -d" # dirs only
ealias treeh "tree -h" # human readable sizes
1..9 | ForEach-Object { ealias "tree$_" "tree -L $_" } # tree -L 1
ealias treeP "tree -P" # -P PATTERN # opposite of -I PATTERN
# tree --help # list all args

function cdr() {
  # PRN add hg_repo_root and make generic repo_root for both:
  Set-Location $(git_repo_root)
}


function take {
  param ( [string] $path )
  mkdir -p $path
  Set-Location $path
}
# *** end dir helpers




# *** rdpclip (fix copy/paste)
function Fix-RdpClip {
  # fixes intermittent copy/paste issues over RDP (mostly macOS => win in my experience)
  Stop-Process -Name rdpclip
  Start-Process -FilePath rdpclip
}


# *** ollama ***
abbr olc "ollama create"
abbr olcp "ollama cp"
abbr olh "ollama help"
abbr oll "ollama list"
abbr olp "ollama pull"
abbr olps "ollama ps"
abbr olpush "ollama push"
abbr olr "ollama run --verbose"
abbr olrm "ollama rm"

#$env:OLLAMA_HOST="http://0.0.0.0:11434"; $env:OLLAMA_DEBUG=2; ollama serve | bat -l log
# PRN - use grc with ollama serve too and write my own coloring config (have claude do it)... do this if I dislike using bat for this
$ollama_serve="ollama serve 2>&1 | bat -pp -l log" # -pp to disable pager and use plain style (no line numbers).. w/o disable pager, on mac my pager setup prohibits streaming somehow (anyways just use this always)
abbr ols "`$env:OLLAMA_NUM_PARALLEL=1; $ollama_serve"
abbr olsd "`$env:OLLAMA_NUM_PARALLEL=1; `$env:OLLAMA_DEBUG=2; $ollama_serve"
abbr olsh "`$env:OLLAMA_NUM_PARALLEL=1; `$env:OLLAMA_KEEP_ALIVE='30m'; `$env:OLLAMA_HOST='http://0.0.0.0:11434'; $ollama_serve"
abbr olshd "`$env:OLLAMA_NUM_PARALLEL=1; `$env:OLLAMA_KEEP_ALIVE='30m'; `$env:OLLAMA_DEBUG=2; `$env:OLLAMA_HOST='http://0.0.0.0:11434'; $ollama_serve"
abbr olshow "ollama show"

