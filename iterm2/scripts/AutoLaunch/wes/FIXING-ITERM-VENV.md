## 2026-02-21 scripted the restore,

```fish
# !!! USE THIS SCRIPT NOW:
fix-iterm2venv.fish
# !!! AND USE IT FOR INSTALLING NEW PACKAGES
```





## 2026-02-21 pyenv failure attempt but should work too
```python
cd ~/repos/github/g0t4/dotfiles/iterm2/scripts/AutoLaunch/wes/iterm2env # this should work too
ls versions # shows already installed
./pyenv/bin/pyenv install 3.10.3
# crap this installed here:
# ++ echo 'Installed Python-3.10.3 to /Users/wesdemos/.pyenv/versions/3.10.3'
# PYENV_ROOT # I tried setting this and it didn't install the same 3.10.3 that worked in ~/.pyenv :(
```

## OLDER NOTES: (prior to 2026-02-21 above), recreate w/ iterm2 (hacky):

- I wiped out the Scripts symlink entirely and made a new Scripts physical dir in
    '/Users/wesdemos/Library/Application Support/iTerm2'
- Then I used the Scripts => Manage => New Python Script
  if it takes you to wrong spot, open in Finder the '/Users/wesdemos/Library/Application Support/iTerm2' and drag the new `Scripts` dir onto the iterm save as dialog
    otherwise it disables navigating to the only spot it allows!! UGH
  call it "wes" to match the name here
    iterm does some funky stupid shit where it requires the "Script" "wes" to have a "wes" dir inside of which it makes a "wes.py" script
      I think you can modify the setup.cfg to change that but just keep in mind...
      thankfully I use that same naming with my github repo where I checkin source code only for the iterm "script"
      I also have to overlay the iterm2env in my checkout but its excluded, here is where its at:
        /Users/wesdemos/repos/github/g0t4/dotfiles/iterm2/scripts/AutoLaunch/wes/iterm2env
          which is git ignored of course
  anyways, you can copy then new iterm2env dir only (I did full  wes folder but then I reset the repo changes to make sure it had my current scripts):
     from new Scripts dir in Application Support
     => `/Users/wesdemos/repos/github/g0t4/dotfiles/iterm2/scripts/AutoLaunch/wes/iterm2env` dir onto
- then put symlink back
  - delete the new '/Users/wesdemos/Library/Application Support/iTerm2/Scripts' dir
  - link back to the repo spot
    I had symlink still there (i renamed it so I just put it back), IIGC here is the right link to create
      ln -s '/Users/wesdemos/repos/github/g0t4/dotfiles/iterm2/scripts/' \
        '/Users/wesdemos/Library/Application Support/iTerm2/Scripts'
      * careful with casing, use command as is here... its captial S in App Support dir.. lowercase in my repo
        careful  with trailing / too ... symlinks are brittle bullshit
- restart neovim and make sure it detects and attempst to run the script
   in the repo its in AutoLaunch so it starts on startup...
   option+Cmd+J shows console, make sure "wes" shows and not "(wes)"...
   that said it might die b/c of missing deps so you need to now add back the missing deps
   BTW... iterm fails to add deps when the Scripts dir is physically  in "Application Support" b/c of the goddamn space in!!!! FUCK who though "Application Support" was a goood motherfucking idea (@apple motherfucking idiots)
       so dont try to install deps before symlinking back to the repo, they will fail
   `cd /Users/wesdemos/repos/github/g0t4/dotfiles/iterm2/scripts/AutoLaunch/wes`
   `./iterm2env/versions/3.10.4/bin/python3 -m pip list`
   `./iterm2env/versions/3.10.4/bin/python3 -m pip install openai`
     # TODO didn't I have other deps too? FML I will have to figure that out if shit is broken
     given I have overrides to use the Wes plugin for many different things in iterm2... i.e. open new tab, split pane, etc... check that those work
       check that you can ask-openai a question and it works in Script Console, no errors
       good to go then
