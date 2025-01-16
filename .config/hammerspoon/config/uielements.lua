local printWebView = nil
local printWebWindow = nil
local printHtmlBuffer = {}
local printWebViewUserContentController = nil

local skipAttrsWhenInspectForPathBuilding = {
    -- PRN truncate long values instead? could pass max length here
    AXValue = true,
    AXTopLevelUIElement = true,
    AXWindow = true,
    AXParent = true,
}

local function prints(...)
    -- PRN www.jstree.com - if I want a tree view that has collapsed sections that hide details initially ... only use this if use case arises from daily use... my hope is generated AppleScript works most of the time
    for _, arg in ipairs({ ... }) do
        if printWebView == nil then
            -- user visible line break == <br>, html src line break == \n
            --   this replace with \n for all line breaks when printing to console
            arg = arg:gsub("<br>", "\n")
            -- PRN strip table tags too?
            print(arg)
        else
            if type(arg) == "string" then
                arg = arg:gsub("\t", "&nbsp;&nbsp;")
                table.insert(printHtmlBuffer, arg)
            else
                print("WARN: unexpected prints arg type: " .. type(arg))
                table.insert(printHtmlBuffer, tostring(arg))
            end
        end
    end
    if printWebView then
        -- PRN debounce updating html when prining in rapid succession (also will apply to scroll to bottom)
        local html = table.concat(printHtmlBuffer, "<br/>")
        printWebView:html(html)

        if false then
            -- disable for now... since I put PATH on top
            require("hs.timer").doAfter(0.1, function()
                -- FYI smth in setting :html(html) above, means I cannot immediatelly scroll to bottom, so I add a slight delay here
                -- FYI last test I did, cannot use setTimeout() in JS to accomplish this so it has smth to do with when I tee up running the JS, not when the JS inside runs
                -- FYI 0.01 is too fast, 0.1 seems to work and appears instant when html content is changed
                local scrollToBottom = [[
                    window.scrollTo(0,document.body.scrollHeight);
                ]]
                printWebView:evaluateJavaScript(scrollToBottom, function(result, nsError)
                    -- AFAICT error is NSError https://developer.apple.com/documentation/foundation/nserror
                    --   error s/b nil if no error... but I also am getting { code = 0 } on successes, so ignore based on code too:
                    if nsError and nsError.code ~= 0 then
                        hs.showError("js failed: " .. hs.inspect(nsError))
                    end
                end)
            end)
        end
    end
end

local function applescriptIdentifierFor(text)
    -- Replace non-alphanumeric characters with underscores
    local identifier = text:gsub("%W", "_")
    -- Trim leading/trailing underscores
    identifier = identifier:gsub("^_+", ""):gsub("_+$", "")
    -- Ensure the identifier starts with a letter or underscore
    if not identifier:match("^[a-zA-Z_]") then
        identifier = "_" .. identifier
    end
    return identifier
end

local function ensureWebview()
    -- do return end -- disable using html printer

    local mouseAt = hs.mouse.absolutePosition() -- {"NSPoint", x = 786.484375, y = 612.0546875 }
    -- print("mouseAt", hs.inspect(mouseAt))

    -- main screen is screen with current focused window (not based on mouse position)
    local whichScreen = hs.screen.mainScreen()
    -- print("whichScreen:id", whichScreen:id())
    -- print("whichScreen:getUUID", whichScreen:getUUID())
    -- print("whichScreen:name", whichScreen:name())
    local frame = whichScreen:frame() -- hs.geometry.rect(0.0,0.0,1920.0,1080.0)
    -- print("frame", hs.inspect(frame))

    local rect = nil
    local midX = frame.w / 2 + frame.x
    -- FYI assumes frame might not start at 0,0
    if mouseAt.x < midX then
        -- mouse is on left side of screen, show webview on right side
        rect = hs.geometry.rect(midX, frame.y, frame.w / 2, frame.h)
        -- print("right rect:", hs.inspect(rect))
    else
        -- mouse is on right, show webview on left
        rect = hs.geometry.rect(frame.x, frame.y, frame.w / 2, frame.h)
        -- print("left rect:", hs.inspect(rect))
    end

    if printWebView == nil then
        -- how to make sure not a new tab in previous browser webview instance?

        -- Enable inspect element (and thus dev tools) in the webview
        --    right click to inspect
        --    FYI more preferencesTable options: https://www.hammerspoon.org/docs/hs.webview.html#new
        --    USE THIS TO TEST JS FIRST!
        local prefs = { ["developerExtrasEnabled"] = true }

        printWebViewUserContentController = require("hs.webview.usercontent").new("testmessageport")
        local jsFilePath = hs.configdir .. "/config/uielements.js" -- Assuming it's saved in the same directory as your Hammerspoon config
        local file = io.open(jsFilePath, "r")
        local jsCode

        if file then
            jsCode = file:read("*a")
            file:close()
        else
            error("Unable to load JavaScript file: " .. jsFilePath)
        end

        printWebViewUserContentController:injectScript({ source = jsCode })


        printWebView = require("hs.webview").newBrowser(rect, prefs, printWebViewUserContentController)

        -- webview:url("https://google.com")
        printWebView:windowTitle("Inspector")
        printWebView:show()
        printWebWindow = printWebView:hswindow()
        printWebView:titleVisibility("hidden")

        printWebView:windowCallback(function(action, _, _)
            -- FYI 2nd arg is webview, 3rd arg is state/frame (depending on action type)
            if action == "closing" then
                printWebView = nil
                printWebViewUserContentController = nil
                printWebWindow = nil
            end
        end)
    else
        -- PRN ensure not minimized
        -- PRN ensure on top w/o modal
        -- right now lets leave it alone if it still exists, that way I can hide it if I don't want it on top
        --   might be useful to have it in background until I capture the element I want and then I can switch to it
    end
    if not printWebWindow then
        prints("no webview window, aborting")
        return
    end
    printWebView:frame(rect)
end


hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "A", function()
    -- [A]ppleScript
    -- FYI "A" is easy to invoke with left hand alone (after position mouse with right--trackpad)
    -- reserve "I" for some other inspect mode? maybe to toggle mouse inspect mode

    if printWebView then
        -- do I want to clear or not?
        printHtmlBuffer = {}
    end
    ensureWebview()
    local coords = hs.mouse.absolutePosition()
    local elementAt = hs.axuielement.systemElementAtPosition(coords.x, coords.y)
    DumpAXPath(elementAt, true)
    -- DumpAXAttributes(elementAt, skipAttrsWhenInspectForPathBuilding)
    local script, attrDumps = BuildAppleScriptTo(elementAt, true)
    prints(script)
    prints(table.unpack(attrDumps))
    -- TODO build lua hammerspoon code instead of just AppleScript! that I can drop into my hammerspoon lua config instead of AppleScript in say KM
end)

local debounced = nil
local stop = nil
local mouseMovesObservable = require("config.rx.mouse").mouseMovesObservable
hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "T", function()
    if not debounced then
        debounced, stop = mouseMovesObservable(400)
        debounced:subscribe(function(position)
            if not position then
                print("[NEXT]", "nil position")
                return
            end
            print("[NEXT]", position.x .. "," .. position.y)
        end, function(error)
            print("[ERROR]", error)
        end, function()
            print("[COMPLETE]")
        end)
    else
        debounced = nil
        if stop then
            stop()
            stop = nil
        end
    end
end)

-- see AppleScript The Definitive Guide, page 197 about Element Specifier forms (name, index, ID, some, every, range, relative, bool test [whose?],...?)
local function elementSpecifierFor(elem)
    local function warnOnEmptyTitle(title, role)
        if title == "" then
            prints("[WARN] title is empty for " .. role .. ", script might not work")
        end
        -- TODO duplicated title (use AXParent to get other child windows)
    end

    local role = GetValueOrEmptyString(elem, "AXRole")
    local roleDescription = GetValueOrEmptyString(elem, "AXRoleDescription")
    local title = GetValueOrEmptyString(elem, "AXTitle")
    if role == "AXApplication" then
        -- TODO handle (warn) about duplicate app process titles... I might then be able to use some signature to identify the correct one but I don't know if I can ever refer to it properly... i.e. screenpal I always had to terminate the tray app b/c has same name and never seemed like I could reference the app by smth else... that said I didn't direclty use accessibiltiy APIs so it is possible there is a way that AppleScript/ScriptDebugger don't support
        warnOnEmptyTitle(title, role)
        -- FYI this is the root most object, aka "object string specifier" (see Definitive Guide book, page 206-207)
        -- app is only top level element (w/o parent) so I don't let it go thru parent logic (don't need to)
        return 'application process "' .. title .. '"'
    end

    local elemIndex = GetElementSiblingIndex(elem)
    if elemIndex == nil then
        -- TODO signal failure to caller
        return " should not happen - failed to get sibling index for " .. role .. " " .. title
    end


    -- PRN use intermediate references, each with a whose/where clause (index == 1 or title == "foo") so I can match on either/both?
    -- FTR, I am mapping role => class, when role description != class
    if role == "AXWindow" then
        warnOnEmptyTitle(title, role)
        -- TODO handle duplicate titles (windows)
        -- PRN use window index instead?
        -- FYI title is an issue in some scenarios (i.e. if title is based on current document, like in Script Debugger)
        -- PRN use title or index match? using intermediate reference vars
        return 'window "' .. title .. '" of '
    elseif role == "AXSplitGroup" then
        return "splitter group " .. elemIndex .. " of "
    elseif role == "AXTextArea" then
        return "text area " .. elemIndex .. " of "
    elseif role == "AXIncrementor" then
        return "incrementor " .. elemIndex .. " of "
    elseif role == "AXPopUpButton" then
        return "pop up button " .. elemIndex .. " of "
    elseif role == "AXList" then
        -- PRN Subrole == "AXSectionList"? does that matter (i.e. diff list types?)
        return "section " .. elemIndex .. " of "
    elseif role == "AXCell" then
        return "cell " .. elemIndex .. " of "
    elseif role == "AXStaticText" then
        return "static text " .. elemIndex .. " of "
    end
    -- FYI pattern, class == roleDesc - AX => split on captial letters (doesn't work for AXApplication, though actually it probably does work as ref to application class in Standard Suite?
    return roleDescription .. " " .. elemIndex .. " of "
end

function BuildAppleScriptTo(toElement, includeAttrDumps)
    includeAttrDumps = includeAttrDumps or false

    local specifierChain = ""
    local attrDumps = {}
    -- REMEMBER toElement is last item in :path() list/table so dont need special handling for it outside of list
    for _, elem in pairs(toElement:path()) do
        if includeAttrDumps then
            -- for testing, don't even run this if not needed (has to have a good perf hit)
            local attrDump = GetDumpAXAttributes(elem, skipAttrsWhenInspectForPathBuilding)
            table.insert(attrDumps, attrDump)
        end

        specifierChain = elementSpecifierFor(elem) .. specifierChain .. '\n'
    end

    local identifier = GetValueOrEmptyString(toElement, "AXTitle")
    if identifier == "" then
        identifier = GetValueOrEmptyString(toElement, "AXDescription")
    end
    if identifier == "" then
        identifier = GetValueOrEmptyString(toElement, "AXRoleDescription")
    end
    if identifier == "" then
        -- TODO does this make sense, ever?
        -- FYI I don't recall seeing AXIdentifier on leaf level ui elements... usually up the chain in a split group
        --   FYI I bet this would change across diff configs of the app so not likely wise beyond current session... that's fine
        identifier = GetValueOrEmptyString(toElement, "AXIdentifier")
    end
    if identifier == "" then
        prints("cannot determine an identifier, using foo")
        identifier = "foo"
    end

    -- IDEAS:
    --   return intermediate references too (for each level, or notable level, i.e. sg1, sg2, sg3, sa4, etc)
    --     consider variable name based on AXIdentifier (if other options fail)

    -- TODO use description if not title?
    -- TODO hungarian notation if title/desc are "too short" or?
    -- TODO build up some test cases would be helpful as you encounter real work examples
    local variableName = applescriptIdentifierFor(identifier)
    return "<br>set " .. variableName .. " to " .. specifierChain, attrDumps
    -- PRN add suggestions section for actions to use and properties to get/set? as examples to copy/pasta
    --    i.e. text area => get/set value, button =>click
end

function DumpAXEverything(element)
    -- TODO header?
    local result = GetDumpAXAttributes(element)
    result = result .. "<br>" .. GetDumpAXActions(element)
    -- PRN add parameterizedAttributes too
    prints(result)
end

function GetValueOrDefault(element, attribute, default)
    local value = element:attributeValue(attribute)
    if value then
        return value
    else
        return default
    end
end

function GetValueOrEmptyString(element, attribute)
    local value = element:attributeValue(attribute)
    if value then
        return value
    else
        return ""
    end
end

function GetDumpAXAttributes(element, skips)
    local function compactUserData(userdata)
        if userdata.__name ~= "hs.axuielement" then
            -- IIUC __name is frequently used so that is a pretty safe bet
            -- getmetatable(value) == hs.getObjectMetatable("hs.axuielement") -- alternate to check
            prints("UNEXPECTED userdata type, consider adding it to display helpers: " .. tostring(userdata))
            return "UNEXPECTED: " .. tostring(userdata)
        end
        local title = GetValueOrEmptyString(userdata, "AXTitle")
        local role = GetValueOrEmptyString(userdata, "AXRole")
        return title .. ' (' .. role .. ')'
    end

    local compactTableAttrValue -- forward define b/c dependency loop and I wanna keepe local funcs

    local function displayAttr(attrValue)
        if attrValue == nil then
            return 'nil'
        elseif type(attrValue) == "userdata" then
            return compactUserData(attrValue)
        elseif type(attrValue) == "table" then
            -- i.e. AXSize, AXPosition, AXFrame, AXVisibleCharacterRange
            return compactTableAttrValue(attrValue)
        elseif type(attrValue) == 'string' then
            return '"' .. attrValue .. '"'
        else
            return tostring(attrValue)
        end
    end

    function compactTableAttrValue(tbl)
        if tbl == nil then
            return "nil"
        end
        local result = {}
        for attrName, attrValue in pairs(tbl) do
            local displayValue = displayAttr(attrValue)
            table.insert(result, string.format("%s=%s", tostring(attrName), displayValue))
        end
        return "{" .. table.concat(result, ", ") .. "}"
    end

    skips = skips or {}

    -- yes, I know this has tr/td tags but it still shows fine for now so I don't need to make GetDumpElementLine() handle non table output too (not yet)
    local result = '## ATTRs - ' .. GetDumpElementLine(element) .. '<br>'

    local sortedAttrs = {}
    for attrName, attrValue in pairs(element) do
        -- TODO skip nil attrValue?
        if not skips[attrName] then
            table.insert(sortedAttrs, attrName)
        end
    end
    table.sort(sortedAttrs)
    for _, attrName in ipairs(sortedAttrs) do
        local attrValue = element[attrName]
        local displayName = attrName
        local nonStandard = not StandardAttributesSet[attrName]
        local displayValue = displayAttr(attrValue)
        if nonStandard then
            displayName = '** ' .. attrName
        end
        result = result .. "\t" .. displayName .. ' = ' .. displayValue .. '<br>'
    end
    return result
end

-- *** non-standard attr identification ***
StandardAttributesSet = {}
for _, value in pairs(hs.axuielement.attributes) do
    StandardAttributesSet[value] = true
end
-- add these as standard too:
StandardAttributesSet["AXFullScreen"] = true
StandardAttributesSet["AXFrame"] = true
StandardAttributesSet["AXPreferredLanguage"] = true
StandardAttributesSet["AXEnhancedUserInterface"] = true
-- AXFunctionRowTopLevelElements ?
-- AXChildrenInNavigationOrder ?
-- TODO AXSections (could this be useful in searching elements?
-- FYI I am using this detection really just to point them out to me so I can figure out what each one is and then exploit if useful
--   once I find something new, its ok to add to this list (so only new stick out)


function DumpAXAttributes(element, skips)
    prints(GetDumpAXAttributes(element, skips))
end

function GetDumpAXActions(element)
    local actions = element:actionNames()
    local result = ' ## NO ACTIONS'
    if #actions > 0 then
        result = '## ACTIONS: '
        for _, action in ipairs(actions) do
            result = result .. action .. ', '
        end
    end
    return result
end

function DumpAXActions(element)
    prints(GetDumpAXActions(element))
end

function GetElementSiblingIndex(elem)
    local parent = elem:attributeValue("AXParent")
    if parent == nil then
        return nil
    end

    -- how expensive is it to get the attribute value here (again)? same for AXParent above
    local role = GetValueOrEmptyString(elem, "AXRole")
    local roleSiblings = parent:childrenWithRole(role)
    local elemIndex = 1
    if #roleSiblings > 1 then
        for i, sibling in ipairs(roleSiblings) do
            if sibling == elem then
                elemIndex = i
            end
        end
    end
    return elemIndex
end

function WrapInQuotesIfNeeded(value)
    return string.find(value, "%s") and '"' .. value .. '"' or value
end

function GetDumpElementLine(elem, indent)
    indent = indent or ""
    local role = GetValueOrEmptyString(elem, "AXRole")
    local title = GetValueOrEmptyString(elem, "AXTitle")
    local subRole = GetValueOrEmptyString(elem, "AXSubrole")
    local identifier = GetValueOrEmptyString(elem, "AXIdentifier")
    -- TODO AXHelp?
    local description = GetValueOrEmptyString(elem, "AXDescription")
    local roleDescription = GetValueOrEmptyString(elem, "AXRoleDescription")
    local elemIndex = GetElementSiblingIndex(elem) or ''

    -- TODO conditions to clear out (not show) AXRole or otherwise
    --    i.e. AXApplication role, desc=application...
    --      AXWindow role, AXStandardWindow subrole... desc=standard window
    --    basically, condense what I show in path view (make it easily decipherable... IOTW always show role and if anything hide rightmost items (i.e. desc) when it doesn't tell me anything new... that is what I dislike about other inspectors, they are hard to decipher what matters (the one thing that doesn't stand out cuz everything else is duplicated)
    --
    -- TODO AXValue
    -- TODO AXValueDescription

    -- TODO add back role (if I go with column view where I keep some attrs in sep columns to avoid cluttering items)
    local col1 = indent .. roleDescription .. ' ' .. elemIndex
    if subRole ~= "" then
        col1 = col1 .. ' (' .. subRole .. ')'
    end
    if title ~= "" then
        col1 = col1 .. ' "' .. title .. '"'
    end

    -- TODO put into separate column too (details)
    local details = ""
    if description ~= "" and description ~= roleDescription then
        -- only show if AXRoleDescription doesn't already cover what AXDescription has
        details = details .. ' desc=' .. WrapInQuotesIfNeeded(description)
    end
    if identifier ~= "" then
        details = details .. ' id=' .. identifier
    end

    return "<tr><td>" .. col1 .. "</td><td>" .. role .. "</td><td>" .. details .. "</td><td>" .. elementSpecifierFor(elem) .. "</td></tr>"
end

local pathTableStart = [[
<style>
table {
    border-collapse: collapse;
    width: 100%;
    min-width: 500px;
}

tr:nth-child(even){background-color: #f2f2f2}

th {
    background-color: #4CAF50;
    color: white;
}

td {
    padding-left: 5px;
    padding-right: 5px;
}

th:nth-child(4),
td:nth-child(4) {
    padding-left: 10px;
    text-align: left;
}
</style>

<table>
    <tr>
        <th align=left>PATH</th>
        <th>role</th>
        <th>details</th>
        <th align=left>specifier</th>
    </tr>
]]
function GetDumpPath(element, expanded)
    expanded = expanded or false
    local path = element:path()
    if #path > 0 then
        local result = pathTableStart
        for _, elem in ipairs(path) do
            local current = GetDumpElementLine(elem)
            result = result .. current .. '\n' -- \n is for html formatting in src

            if expanded then
                local children = elem:attributeValue("AXChildren")
                if children == nil then
                    children = {}
                end
                for _, child in pairs(children) do
                    result = result .. GetDumpElementLine(child, "\t\t") .. "\n"
                end
            end
        end
        result = result .. "</table>\n"
        return result
    else
        return "NO PATH - should not happen, even AXApplication (top level) has self as path"
    end
end

function DumpAXPath(element, expanded)
    prints(GetDumpPath(element, expanded))
end
