./test.fish works inside iterm... (this is osascript => applescript, not using compiled .app)

- TODO read applescript book about building .app Applications w/ applescript, chances are I am just missing something (esp w.r.t. being a default applicaiton for a file type handler)
   - odd enough, when I just had `display dialog "foo"` in the script that would run from double clicking the ~/Applications/wes-dispatcher.app in finder (no params) but then that didn't work for double click a file README.md to show dialog)

- FYI when I ran script in iTerm it prompted me to setup perms for what appear to be Automation => wes-dispatcher.app (IIRC)... look into that too

- ~/Applications/wes-dispatcher.app
  - app installs fine and duti can map to it but open a mapped file (ie README.md) from Finder launches smth that never runs... IIAC there is some permission needed or otherwise...
  - run app w/o a file => (w/ no args) it does give an error that indicates that something failed in running the script but that is not how this is supposed to run anyways so yeah...
     - error suggests iterm2 py library can't connect to iterm2's web socket
     - oddly ... I don't get this error when I launch via double click README.md

TODO find out why it won't run as app but will run fine as script... smth wtih the damn app that might need tweaked with plistbuddy?
