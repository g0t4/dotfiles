#!/usr/bin/env fish -i

# defaults export com.colliderli.iina iina.plist

# export as xml
plutil -convert xml1 ~/Library/Preferences/com.colliderli.iina.plist -o iina.plist

# alternatively, I could allow list the keys to keep
#   I like idea of denylist b/c then I am forced to review new keys from settings I might've changed recently though

# FYI seems like settings keys start lowercase, so might wanna filter on that primarily or just when reviewing use that to consider what to keep

# TODO move common keys to a shared file to filter from all plists once I add this to more apps
set rm_keys MainWindowLastPosition NSFullScreenMenuItemEverywhere \
    NSNavPanelExpandedSizeForOpenMode NSOSPLastRootDirectory \
    recentDocuments "NSWindow Frame IINAWelcomeWindow" \
    "NSWindow Frame IINAInspectorPanel" "NSWindow Frame IINAPreferenceWindow" \
    "NSWindow Frame NSColorPanel" "NSWindow Frame NSNavPanelAutosaveName" \
    "NSToolbar Configuration com.apple.NSColorPanel" \
    "NSSplitView Subview Frames NSColorPanelSplitView" \
    iinaLastPlayedFilePath iinaLastPlayedFilePosition \
    controlBarPositionHorizontal controlBarPositionVertical

# exclude anything that would vary (ie window positions, last played file)
for key in $rm_keys
    /usr/libexec/PlistBuddy -c "Delete ':$key'" iina.plist
end


# critical settings:
#   currentInputConfigName => VLC Default  # for now, use vlc keys that I already know
