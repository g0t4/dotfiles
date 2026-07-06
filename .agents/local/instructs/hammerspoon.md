# Verifying Hammerspoon Code

## Two Approaches to Hammerspoon Code

There are two distinct ways to execute Lua code in Hammerspoon:


### 1. **Startup-Loaded Code**
Loaded when Hammerspoon starts

**Use this for:**
- Code that should persist across restarts
- Production-ready code (i.e. app automation macros)
- Reusable code

**Characteristics:**
- Stored in my `dotfiles` repo, primarily in `.config/hammerspoon/config/` which is symlinked to `~/.hammerspoon/config`
  - hence imports start with `require("config.`
- Root most import is `~/.hammerspoon/init.lua` which symlinks to `~/.config/hammerspoon/init.lua` in this repo
- Restart to load changes: `hs -c hs.reload()`


### 2. **Exploratory Code**
Code you send to the `hs` command

```bash
# INLINE code
hs -c 'print("foo")' -c 'print("bar")'

# script FILE
hs ./test.lua # relative paths must start with `./`
hs ./../test.lua
hs /abs/path/to/test.lua
hs ~/test.lua

# HEREDOC
hs <<'EOF'
local rect = hs.geometry.rect(100, 100, 200, 100)
local myRect = hs.drawing.rectangle(rect)
myRect:setFillColor({ red = 1.0, green = 0.0, blue = 0.0, alpha = 1.0 })
myRect:setFill(true)
myRect:show()
EOF
```

**Use this for:**
- Exploring AXUIElement controls
- Testing assumptions
- Quick experiments
- Verifying API availability


### 3. Best of Both Worlds
Combine one-off and startup loaded code!
- Modify a macro => reload hs => call macro via hs CLI
- All code runs in the same hammerspoon process, same lua VM
- Same globals
- Same imports

## Example: Develop a ScreenPal Macro to Open a Project

### Step 1: Explore (CLI Code)
```bash
hs -c '
local ScreenPalEditorWindow = require("config.macros.screenpal.editor_window")
local editor_window = get_cached_editor_window()
local projects = editor_window:get_project_buttons()
for i, p in ipairs(projects) do
    print(i .. ". " .. p)
end
'
```

**Result:** Found 13 projects! Confirmed `get_all_projects()` works.

### Step 2: Create Reusable Macro (Startup Code)
Create `config/macros/screenpal/windows/projects.lua` with:

```lua
local ScreenPalEditorWindow = require('config.macros.screenpal.editor_window')

return {
    open_project = function(name)
        local editor_window = get_cached_editor_window()
        local projects = editor_window:get_project_buttons()
        for _, p in ipairs(projects) do
            if p.name == name then
                p:axPress()
                return
            end
        end
        print("Project not found:", name)
    end
}
```

### Step 3: Reload config changes
```bash
hs -c 'hs.reload()'
```

### Step 4: Test the Macro (CLI Code)
```bash
hs -c '
local projects = require("config.macros.screenpal.windows.projects")
projects.open_project("MyProject")
projects.back_to_project_list()
'
```
