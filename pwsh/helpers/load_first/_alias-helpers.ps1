using namespace System.Management.Automation
using namespace System.Management.Automation.Language

$_ealiases = [ordered]@{}

function _lookup_ealias() {
  param([string]$Name)

  $metadata = _lookup_ealias_metadata($Name)
  if ($null -eq $metadata) {
    return $null
  }
  return $metadata.ExpandsTo
}

function _lookup_ealias_metadata() {
  param([string]$Name)
  return $_ealiases[$Name]
}

function abbr() {
  # for compat w/ fish abbr (that zsh now understands)
  #   BONUS: abbr uses two args like ealias (below) in powershell, so finally I can have one style across ps1,zsh,fish for vanilla expansions!
  # PRN if it saves time make abbr into expansion only, leave ealias for composable+expansions like fish (and maybe port to zsh too)... if it doesn't matter for startup time then don't bother
  ealias $args[0] $args[1]
}

function ealias() {
  # usage:
  #   ealias foo bar
  #   ealias gcmsg 'git commit -m "' -NoSpaceAfter
  #   ealias pyml '| yq' -Anywhere => 'kubectl get pods -o yaml pyml[EXPANDS]'
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$ExpandsTo,
    [Parameter(Mandatory=$false)][switch]$NoSpaceAfter,
    [Parameter(Mandatory=$false)][switch]$Anywhere
  )

  # *** use set-alias to see the $_cmd in MENU COMPLETION TOOL TIPS
  #   also allows `gcm foo` to lookup expanding aliases
  Set-Alias $Name "$ExpandsTo" -Scope Global

  # metadata/lookup outside of set-alias objects
  $_ealiases[$Name] = @{
    ExpandsTo = $ExpandsTo
    NoSpaceAfter = $NoSpaceAfter
    Anywhere = $Anywhere
  }

}

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

function ExpandAliasBeforeCursor {
    param($key, $arg)

    # Add space, then invoke replacement logic
    #   b/c override spacebar handler, there won't be a space unless I add it
    # inserts at current cursor position - important to do that now b/c the cursor is where the user intended the space, whereas after modification the cursor might be elsewhere (ie after Replace below)
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert(" ")
    # help for Insert overloads
    # https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.psconsolereadline.insert

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    # this must handle cumulative adjustments from multiple replaces but the thing is after each space I would've already replaced previous ealiases
    #   in fact if I copy/paste smth like `dcr dcr dcr` the spaces trigger on paste to expand already
    #   so, I theoretically could stop after first replacement
    $startAdjustment = 0

    foreach ($token in $tokens) {
      # PRN revise this to only expand LAST TOKEN (before space triggered)... did I do all b/c I was lazy about finding what token was right before cursor? or couldn't find that out (i.e. space in middle of a command line where cursor not at end of command line?)

      $original = $token.Extent

      $metadata = _lookup_ealias_metadata($original.Text)
      if ($metadata -eq $null -or $metadata.ExpandsTo -eq $null) {
        continue
      }

      $anywhere = $metadata.Anywhere
      $is_command_position = $token -eq $tokens[0] # PRN if this has edge cases where command isn't first token, then address that once the problem arises, for now assume this works (to check $tokens[0])
      if (-not $anywhere -and -not $is_command_position){
        # skip if not in command position and not marked anywhere
        continue
      }

      $expands_to = $metadata.ExpandsTo

      if (-not $metadata.NoSpaceAfter) {
        # add a space unless alias defined with NoSpaceAfter
        #   i.e. `gcmsg` expands to `git commit -m "` w/o trailing space
        $expands_to = "$expands_to "

        # IIRC I had an open question about why I have to add space here again... but its working as is so leave it, IIAC this is b/c tokenizer strips them?
      }

      $original_length = $original.EndOffset - $original.StartOffset
      [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
          $original.StartOffset + $startAdjustment,
          $original_length,
          $expands_to)

      # Our copy of tokens isn't updated, so adjust by the difference in length
      $startAdjustment += $expands_to.Length - $original_length
    }

    # PRN => if any expansions then take another pass! until no more expansions b/c then I can supported nested expansions!
    # i.e.:
    #   ealias foo bar
    #   ealias bar baz
    #   foo => expands to `bar` => expands to `baz`
    #   right now I only expand to `bar` and stop which has been sufficient for now

}

### Spacebar => triggers expansion
#
# scenarios:
# - typing `drc<SPACE>` => expands
# - completion: `gs<TAB>` => menu shows, tab through items, hit space to select (triggers expand)
#   - if I hit enter to select an item, space can be used after that to expand it => PRN I could impl a handler for enter during completion but lets not complicate it
#
Set-PSReadLineKeyHandler -Key "Spacebar" `
    -BriefDescription "space expands ealiases" `
    -LongDescription "Spacebar handler to expand all ealiases in current line/buffer, primarily intended for ealias right before current cursor position" `
    -ScriptBlock ${function:ExpandAliasBeforeCursor}


### ENTER => triggers expansion
# i.e. if type `dcr<ENTER>` it expands to `docker-compose run` b/c of this
#
# enable validate handler (on enter):
Set-PSReadLineKeyHandler -Key Enter -Function ValidateAndAcceptLine
#

function ExpandAliasesCommandValidationHandler {
  param([CommandAst]$CommandAst)

  # I split out this function so end users can re-compose it with additional validation handler logic of their own

  $possibleAlias = $CommandAst.GetCommandName()
  # don't need metadata b/c NoSpaceAfter (only option) doesn't apply to this handler b/c this is after executing the command (possible alias) so line editing is done
  $expands_to = _lookup_ealias($possibleAlias)
  if ($null -eq $expands_to) {
    return
  }

  $original = $CommandAst.CommandElements[0].Extent
  [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
    $original.StartOffset,
    $original.EndOffset - $original.StartOffset,
    $expands_to
  )

}

Set-PSReadLineOption -CommandValidationHandler ${function:ExpandAliasesCommandValidationHandler}

## Examples
# CommandValidationHandler: https://github.com/PowerShell/PSReadLine/issues/1643
# https://www.powershellgallery.com/packages/PSReadline/1.2/Content/SamplePSReadlineProfile.ps1

Set-PSReadLineKeyHandler -Key ctrl+d -ScriptBlock {
  # make sure to use lowercase e on -Key else uppercase is literally bound just to that, not:Ctrl+E, use Ctrl+e

  [Microsoft.PowerShell.PSConsoleReadLine]::KillLine() # clear line so exit works

  # run exit command
  [Microsoft.PowerShell.PSConsoleReadLine]::Insert("exit")
  [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()

}