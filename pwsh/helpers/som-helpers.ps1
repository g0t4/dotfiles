
function Stop-ProcessForSure {
    param (
        [string] $ProcessName
        )

    # first gracefully tries to stop it, then kills it

    Get-Process -Name $ProcessName -ErrorAction SilentlyContinue `
    | Stop-Process `
    | Wait-Process -Timeout 5
}

Set-Alias ks Kill-ScreenPal
function Kill-ScreenPal {
    Stop-ProcessForSure "ScreenPal"
}

Set-Alias us Use-ScreenPalOnly
function Use-ScreenPalOnly {
    Kill-DropBox
    explorer.exe "C:\Users\wes\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\ScreenPal.lnk"
}

Set-Alias rs Restart-ScreenPal
function Restart-ScreenPal {
    Kill-ScreenPal
    Use-ScreenPalOnly
}

Set-Alias kd Kill-DropBox
function Kill-DropBox {
    Stop-ProcessForSure "DropBox"
}

Set-Alias ud Use-DropBoxOnly
function Use-DropboxOnly {
    Kill-ScreenPal
    explorer.exe "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Dropbox\Dropbox.lnk"
}
