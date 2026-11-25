#!/usr/bin/env fish

set -l source_plist (status dirname)/iina.plist
set -l tmp_dir (mktemp -d); or exit 1
function cleanup --on-event fish_exit --inherit-variable tmp_dir
    rm -rf -- "$tmp_dir"
end
# new.plist will start with my versioned settings (so they win over current.plist)
cp "$source_plist" "$tmp_dir/new.plist"; or exit 1
cd "$tmp_dir"; or exit 1

# *** FYI merge does not overwrite so I have to jump through hoops to take iina.plist and merge it into actual iina plist without clobbering other settings
# TODO I should verify there is no way to import this way with an existing tool, seems like it should be possible

# export current iina settings to `current.plist` so we can merge it into new.plist
plutil -convert xml1 ~/Library/Preferences/com.colliderli.iina.plist -o current.plist
if test $status -ne 0
    echo "Failed to EXPORT current iina settings to current.plist"
    exit 1
end

# now, add any keys not in versioned settings, into final new.plist (so I don't wipe out any current settings that are not versioned)
/usr/libexec/PlistBuddy -x -c "Merge current.plist" new.plist
if test $status -ne 0
    echo "Failed to MERGE current iina settings into new.plist"
    exit 1
end

# now, import merged plist:
plutil -convert binary1 new.plist -o ~/Library/Preferences/com.colliderli.iina.plist
if test $status -ne 0
    echo "Failed to IMPORT new iina settings"
    exit 1
end
