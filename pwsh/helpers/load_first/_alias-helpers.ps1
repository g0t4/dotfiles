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

function ealias() {
  # usage:
  #   ealias foo bar
  #   ealias gcmsg 'git commit -m "' -NoSpaceAfter
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$ExpandsTo,
    [Parameter(Mandatory=$false)][switch]$NoSpaceAfter
  )

  # *** use set-alias to see the $_cmd in MENU COMPLETION TOOL TIPS
  #   also allows `gcm foo` to lookup expanding aliases
  Set-Alias $Name "$ExpandsTo" -Scope Global

  # metadata/lookup outside of set-alias objects
  $_ealiases[$Name] = @{
    ExpandsTo = $ExpandsTo
    NoSpaceAfter = $NoSpaceAfter
  }

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
    -LongDescription "Spacebar handler to expand all ealiases in current line/buffer" `
    -ScriptBlock {
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

      $original = $token.Extent
      $metadata = _lookup_ealias_metadata($original.Text)
      if ($metadata -eq $null -or $metadata.ExpandsTo -eq $null) {
        continue
      }
      $expands_to = $metadata.ExpandsTo

      if (-not $metadata.NoSpaceAfter) {
        # add a space unless alias defined with NoSpaceAfter
        #   i.e. `gcmsg` expands to `git commit -m "` w/o trailing space
        $expands_to = "$expands_to "

        # IIRC I had an open question about why I have to add space here again... but its working as is so leave it, IIAC this is b/c tokenizer strips them?
        #   TODO port this to zsh widgets too!
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


### ENTER => triggers expansion
# i.e. if type `dcr<ENTER>` it expands to `docker-compose run` b/c of this
#
# enable validate handler (on enter):
Set-PSReadLineKeyHandler -Key Enter -Function ValidateAndAcceptLine
#
Set-PSReadLineOption -CommandValidationHandler {
    param([CommandAst]$CommandAst)

    $possibleAlias = $CommandAst.GetCommandName()
    # don't need metadata b/c NoSpaceAfter (only option) doesn't apply to this handler b/c this is after executing the command (possible alias) so line editing is done
    $expands_to = _lookup_ealias($possibleAlias)
    if ($expands_to -eq $null) {
      return
    }

    $original = $CommandAst.CommandElements[0].Extent
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
        $original.StartOffset,
        $original.EndOffset - $original.StartOffset,
        $expands_to
    )
}


## Examples
# CommandValidationHandler: https://github.com/PowerShell/PSReadLine/issues/1643
# https://www.powershellgallery.com/packages/PSReadline/1.2/Content/SamplePSReadlineProfile.ps1


### Alt+% triggers replace all aliases
#
# ! vestigial?
# ? when might I actually use this... even on copy/paste multiple aliases they already expand b/c of spacebar handler
#   could be used to recursively expand nested aliases (but that can be added to spacebar above too)
#
# Largely copied from this sample (other examples too):
#    - https://github.com/PowerShell/PSReadLine/blob/a88c22fd60a69f41d1b727b7c51b5cbf8f9b5f68/PSReadLine/SamplePSReadLineProfile.ps1#L439-L477
#
Set-PSReadLineKeyHandler -Key "Alt+%" `
-BriefDescription ExpandAliases `
-LongDescription "Replace all aliases with the full command" `
    -ScriptBlock {
    param($key, $arg)


    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)


    $startAdjustment = 0
    foreach ($token in $tokens) {
      $original = $token.Extent

      if ($token.TokenFlags -band [TokenFlags]::CommandName) {
        # IIAC this lookup happens via the alias value (not using lookup_alias)
        $alias = $ExecutionContext.InvokeCommand.GetCommand($original.Text, 'Alias')
        if ($alias -ne $null) {
          #$expands_to = $alias.ResolvedCommandName
          $expands_to = $alias.Definition
          if ($expands_to -ne $null) {
            $original_length = $original.EndOffset - $original.StartOffset
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                $original.StartOffset + $startAdjustment,
                $original_length,
                $expands_to)

            # support matching multiple aliases (startAdjustment adjusts for cumulative replacements)
            $startAdjustment += ($expands_to.Length - $original_length)
          }
        }
      }
    }
}
