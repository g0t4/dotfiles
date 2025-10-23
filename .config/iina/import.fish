#!/usr/bin/env fish -i

remkdir tmp

# *** FYI merge does not overwrite so I have to jump through hoops to take iina.plist and merge it into actual iina plist without clobbering other settings
# TODO I should verify there is no way to import this way with an existing tool, seems like it should be possible

# export current iina settings to `current.plist` so we can merge it into new.plist
plutil -convert xml1 ~/Library/Preferences/com.colliderli.iina.plist -o tmp/current.plist
if test $status -ne 0
    echo "Failed to EXPORT current iina settings to current.plist"
    exit 1
end

# new.plist will start with my versioned settings (so they win over current.plist)
cp iina.plist tmp/new.plist

# now, add any keys not in versioned settings, into final new.plist (so I don't wipe out any current settings that are not versioned)
/usr/libexec/PlistBuddy -x -c "Merge tmp/current.plist" tmp/new.plist
if test $status -ne 0
    echo "Failed to MERGE current iina settings into new.plist"
    exit 1
end

# now, import merged plist:
plutil -convert binary1 tmp/new.plist -o ~/Library/Preferences/com.colliderli.iina.plist
if test $status -ne 0
    echo "Failed to IMPORT new iina settings"
    exit 1
end
