using namespace Microsoft.PowerShell


Set-PSReadLineKeyHandler -Chord "Ctrl+b" -BriefDescription "Ask OpenAI to generate a command" -ScriptBlock {

    [string]$userInput = $null
    [int]$cursor = $null
    [PSConsoleReadLine]::GetBufferState([ref]$userInput, [ref]$cursor)
    # https://github.com/powershell/psreadline/blob/master/PSReadLine/PublicAPI.cs#L169

    # append "thinking..."
    [PSConsoleReadLine]::SetCursorPosition($userInput.Length) # ensure end of input (not just current line)
    [PSConsoleReadLine]::Insert($userInput.EndsWith(" ") ? " # thinking..." : " # thinking...")
    # Start-Sleep -Seconds 2 # delay to see thinking when hard coded `test result` below

    $context = "env: powershell`nquestion: $userInput"

    # $output = "hard coded test result"
    $_python = "${WESCONFIG_BOOTSTRAP}\.venv\Scripts\python.exe"
    $_single_py = "${WESCONFIG_DOTFILES}\zsh\universals\3-last\ask-openai\single.py"
    $output = $(`
            Write-Output $context | `
            & $_python "$_single_py" `
            2>&1
        # make sure to pipe stderr to stdout so it is captured in $output (i.e. missing pip install openai module)
    )

    if ($LASTEXITCODE -eq 2) {
        # dump context:
        $output = "[CONTEXT]:`n$output"
    }
    elseif ($LASTEXITCODE -ne 0) {
        # prefix as failure b/c it will be in the buffer for user to see
        $output = "[FAILURE]: $output"
    }

    # replace entire buffer with generated command
    [PSConsoleReadLine]::GetBufferState([ref]$userInput, [ref]$cursor) # get length after append "thinking"
    [PSConsoleReadLine]::Replace(0, $userInput.Length, $output)

    # pinnacle test is to setup two line command and move cursor to middle of first line and then hit ctrl+b and make sure append and replace work as expected (use sleep between w/ hardcoded result to easily test w/o invoking API)
    # - though, single line question is fine too (not robustly tested for multi line question b/c why?)
}



## NOTES
#  https://github.com/powershell/psreadline/blob/e57f7d691d8df8c1121fddf47084f96aea74a688/PSReadLine/SamplePSReadLineProfile.ps1#L50
