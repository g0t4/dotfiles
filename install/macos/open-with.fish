#!/usr/bin/env fish

if not command -q duti
    echo "installing duti"
    if not $USER = wes
        echo "not running as wes, not using brew install, aborting..."
        return
    end
    brew install duti
end

for item in applescript scpt scptd
    duti -s com.latenightsw.ScriptDebugger8 $item all
end

duti -s freemind.main.FreeMind mm all

for item in csv xls xlsx
    duti -s com.microsoft.Excel $item all
end

for item in wav mp3 mpc m4a m4v m4b mp4 m4p mpg mp2 mpeg mpe mpv m2v svi mxf roq nsv 3gp 3g2 aac aiff alac dvf msv flac gsm ogg ogv oga mogg opus ra rm rmvb raw tta voc wma wv webm mkv flv f4v f4p f4a f4b vob gif gifv mng avi mts m2ts ts mov qt wmv viv asf amv
    # list of audio file extension: https://en.wikipedia.org/wiki/Audio_file_format#List_of_formats
    # list of video file formats: https://en.wikipedia.org/wiki/Video_file_format

    # duti -s org.videolan.vlc $item all
    duti -s com.colliderli.iina $item all
    # TEST DRIVE iina for video playback (i.e. back a frame, not just forward... though sometimes back doesn't work)
end

set exts xml dtd plist
set exts $exts cpp c h hpp
set exts $exts cnf conf cfg def
set exts $exts lua vim vimrc
set exts $exts md yaml yml txt toml ini json json5
set exts $exts bash fish zsh sh csh ps1
# TODO htm/html doesn't work currently (blocked by macOS):
set exts $exts css js
set exts $exts py
set exts $exts cs csproj fsproj sln proj
set exts $exts iqy svg meta sdef
set exts $exts asm

for item in $exts
    # TODO FIX: html htm - cannot be set => https://github.com/moretension/duti/issues/34
    # my automator app that just calls my semantich handler like alfred does!
    # PRN in the future modify that app to dispatch to other scripts too.. if so just put some logic in a script in dotfiles to do that and plug it in
    # FYI app is backed up in dropbox
    duti -s com.apple.automator.wes-dispatcher $item all
    #duti -s com.microsoft.VSCode $item all
    # !!! TODO migrate to my nvim-window semantic handler (adapter to use it instead of vscode)

    # 'iqy', # excel web connection scraping definition files
end

# ** test duti mapping points at correct application
#   testing one works means all works as far as the domain (app) => path mapping is concerned
set test_duti_js_output (duti -x js)
if not string match --quiet --regex "$HOME/Applications/wes-dispatcher.app" $test_duti_js_output
    echo "FUUUUU wes dispatcher path doesn't match expected path, this happened previously (wesdemos pointed at wes user's app)... at the time I had to change it by setting an invalid value and then setting the above again... that seemed to work and IIRC just setting it to the correct (same) value didn't fix it... smth to do with mapping from domain (com.apple.automator.wes-dispatcher) to the app on disk... why can't I just pass a path to the app?!"
    echo "'duti -x js' resulted in:\n $test_duti_js_output"
end

# *** OLD NOTES (from ansible playbook):
#
# list existing associations (DUTI cannot do this)
#   defaults read  ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist LSHandlers
# delete association - neither DUTI nor defaults command can remove entires from an array (defaults can add entries lolz)
#   ls /usr/libexec/PlistBuddy  # seems capable of deleting
#     https://medium.com/@marksiu/what-is-plistbuddy-76cb4f0c262d
#  /usr/libexec/PlistBuddy -h
#  Usage:
#    REPL that you open with a file:
#       /usr/libexec/PlistBuddy ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
#          Use Print command first
#          Help shows commands
#       Show all associations:
#          Print LSHandlers
#       Show one association from array (by index):
#          Print LSHandlers:1
#       Remove by index:
#          Delete LSHandlers:3
#          Save
#          Quit
#
#       Set by index:?
#          ??? Set LSHandlers:2 ... # todo
#       FYI plutil will show index numbers for array items BUT PLISTBUDDY DOES NOT!
#           plutil -p ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
#    THEN HAVE TO restart launch services (log out / log in) to apply changes
#
# duti modifies launch services:
#   ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
#     display existing mappings:
#       plutil -p ~/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist
#     todo remove mappings?
#       duti cannot remove and/or even show mappings (except by extension with -x)
# how to edit Launch Services plist ???:
#    maybe - WIP on how to use this:
#   https://stackoverflow.com/questions/9172226/how-to-set-default-application-for-specific-file-types-in-mac-os-x
#       defaults write com.apple.LaunchServices LSHandlers -array-add '{ LSHandlerContentType = "public.comma-separated-values-text"; LSHandlerRoleAll = "com.apple.TextEdit"; }'
#      /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -r -domain local -domain system -domain user
