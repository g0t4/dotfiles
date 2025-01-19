#!/usr/bin/env fish


if test -d ~/Applications/wes-dispatcher.app
    trash ~/Applications/wes-dispatcher.app
end

osacompile -o ~/Applications/wes-dispatcher.app  wes-dispatcher.applescript

## inject a bundle id for the app
/usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string com.yourdomain.yourapp" ~/Applications/wes-dispatcher.app/Contents/Info.plist

# set if exists:
#/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.yourdomain.yourapp" ~/Applications/wes-dispatcher.app/Contents/Info.plist


# FYI might need to open app manually one time before using duti -s to register the app
