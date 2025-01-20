local fun = require "fun"
local printWebView = nil
local printWebWindow = nil
local printHtmlBuffer = {}
local printWebViewUserContentController = nil
local htmlPage

local skipAttrsWhenInspectForPathBuilding = {
    -- PRN truncate long values instead? could pass max length here
    AXValue = true,
    AXTopLevelUIElement = true,
    AXWindow = true,
    AXParent = true,
}

local function readEntireFile(configRelativePath)
    local fullPath = hs.configdir .. "/" .. configRelativePath
    local file = io.open(fullPath, "r")

    if not file then
        error("Unable to read file: " .. fullPath)
        return nil
    end

    local contents = file:read("*a")
    file:close()
    return contents
end

local function prints(...)
    -- PRN www.jstree.com - if I want a tree view that has collapsed sections that hide details initially ... only use this if use case arises from daily use... my hope is generated AppleScript works most of the time
    for _, arg in ipairs({ ... }) do
        if printWebView == nil then
            -- if no web view to print to, then print to console

            -- user visible line break == <br>, html src line break == \n
            --   this replace with \n for all line breaks when printing to console
            arg = arg:gsub("<br>", "\n")
            -- PRN strip table tags too?
            print(arg)
        else
            if type(arg) == "string" then
                arg = arg:gsub("\t", "&nbsp;&nbsp;")
                table.insert(printHtmlBuffer, arg)
            elseif type(arg) == "number" then
                table.insert(printHtmlBuffer, tostring(arg))
            else
                print("WARN: unexpected prints arg type: " .. type(arg))
                table.insert(printHtmlBuffer, tostring(arg))
            end
        end
    end
    if printWebView then
        if not htmlPage then
            -- basically the <head> section with js/css, don't worry about proper body ... just print after this
            htmlPage = readEntireFile("config/uielements.html")
            if not htmlPage then
                htmlPage = "<h1>FAILED TO LOAD uielements.html</h1>"
            end
        end
        -- PRN debounce updating html when prining in rapid succession (also will apply to scroll to bottom)
        local html = htmlPage .. table.concat(printHtmlBuffer, "<br/>")
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
    local halfWidth = frame.w / 2
    local midX = halfWidth + frame.x
    -- FYI assumes frame might not start at 0,0
    if mouseAt.x < midX then
        -- mouse is on left side of screen, show webview on right side
        rect = hs.geometry.rect(midX, frame.y, halfWidth, frame.h)
        -- print("right rect:", hs.inspect(rect))
    else
        -- mouse is on right, show webview on left
        rect = hs.geometry.rect(frame.x, frame.y, halfWidth, frame.h)
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

        local jsCode = readEntireFile("config/uielements.js")
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
    print("raising")
    printWebWindow:raise() -- ensure on top for Hammerspoon app
    printWebWindow:application():activate() -- ensure Hammerspoon app is front most too (else all app windows remain in the background)
end


function InspectHtml(value, completed)
    completed = completed or {}

    local isBuildTreeTableOfAxUiElement = type(value) == "table" and value["_element"]
    local referenceName = ""
    if isBuildTreeTableOfAxUiElement then
        -- PRN add back:
        --    type(value) == "userdata" or
        --    IF AND WHEN I add _inspectUserData pathway that recursively calls InspectHtml (for some child attr/property)
        --
        -- don't repeat showing same objects (userdata, or tables of axuielement info from buildTree)
        -- FYI do not ban all dup tables b/c then coordinates are a mess for example, will only show first time
        if completed[value] then
            referenceName = type(value) .. completed[value]
            return "<span style='color:red'>Repeated #" .. referenceName .. "</span>"
        end

        -- this way I can use the index into completed tabl as an identifier to know which is the first time it was dumped
        local completedNumber = completed.nextNumber or 1 -- track # as extra field so it is passed too (effectively by ref)
        completed[value] = completedNumber
        completed.nextNumber = completedNumber + 1
        referenceName = type(value) .. completedNumber -- so I can link back to the first time the reference is displayed, in future occurences
        -- prints(referenceName)
    end

    local function _inspectTable(tbl)
        -- helper only for InspectHTML, don't use this directly
        -- FYI I like that this prints each level (unlike hs.inspect which consolidates tables with one item in them,  mine shows the actual index of each, within each table)
        local html = "<ul>"
        if referenceName ~= "" then
            -- show right before the table's nested list (ul)
            html = referenceName .. "<ul>"
        end

        for k, v in pairs(tbl) do
            -- FYI if you use hs.inspect output for this table, anywhere that it doesn't show a table value is probably a wise spot to also not show a table in html, i.e.:
            --   AXParent = <table 215>,
            --   IIAC this is hardcoded logic behind hs.inspect to avoid stack overflow and/or cyclical inspection?
            --   TODO review hs.inspect approach to decide what to show and where.. does it show first time an obj is encountered (then show ref on subsequent encounters)....
            --      OR, does it also have any logic like this where it prefers not to show a given object in specific locations (i.e. AXVisibleChildren would not be preferrable to first the obj itself is encountered...)
            --
            -- local isHsInspectSkippedKey = k == "AXWindow" or k == "AXWindows"
            --     or k == "AXVisibleChildren" -- already have "AXChildren"
            --     or k == "AXParent" or k == "AXTopLevelUIElement"
            --     or k == "AXSections"
            --     or k == "AXMainWindow" or k == "AXFocusedWindow" -- AXWindows is sufficient
            --     or k == "AXTitleUIElement" or k == "AXMenuItemPrimaryUIElement"
            --     or k == "AXChildrenInNavigationOrder"
            --     or k == "AXExtrasMenuBar" or k == "AXMenuBar"
            --     or k == "_element" or k == "_attributes"

            -- if isBuildTreeTableOfAxUiElement and isHsInspectSkippedKey then
            --     html = html .. string.format("<li>%s: %s</li>", hs.inspect(k), "SKIPPED")
            -- else
            html = html .. string.format("<li>%s: %s</li>", hs.inspect(k), InspectHtml(v, completed))
            -- end
        end
        return html .. "</ul>"
    end

    local function _inspectUserData(userdata)
        local userdataType = userdata["__type"] -- nil if not set (i.e. non hammerspoon userdata types)
        if userdataType == "hs.axuielement" then
            local axType = userdata["AXRole"] or ""
            local axTitle = WrapInQuotesIfNeeded(userdata["AXTitle"])
            local axDesc = WrapInQuotesIfNeeded(userdata["AXDescription"])
            -- FYI in this case, do not show hs.axuielement b/c AX* indicates that already so save the space
            return string.format("%s %s %s %s", referenceName, axType, axTitle, axDesc)
        elseif userdataType == "hs.application" then
            local appName = userdata:name()
            local appBundleID = userdata:bundleID()
            -- in this case, app name alone isn't enough of hint so show the type 'hs.application'
            return string.format("hs.application(%s) - %s %s", referenceName, appName, appBundleID)
        end

        -- TODO handle other hammerspoon userdata types
        return referenceName .. hs.inspect(userdata) .. " - TODO add this hs type to inspectHTML"
    end

    if value == nil then
        return "nil"
    elseif type(value) == "table" then
        return _inspectTable(value)
    elseif type(value) == "string" then
        return value
    elseif type(value) == "number" or type(value) == "boolean" then
        return tostring(value)
    elseif type(value) == "userdata" then
        return _inspectUserData(value)
    else
        return hs.inspect(value)
    end
end

function DumpHtml(value)
    prints(InspectHtml(value))
end

local function ensureClearedWebView()
    if printWebView then
        printHtmlBuffer = {}
    end
    ensureWebview()
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "S", function()
    -- [S]earch menu items

    ensureClearedWebView()

    local app = hs.application.frontmostApplication()
    print("starting potentially slow element search of: " .. app:name())

    local menuItems = app:findMenuItem("Activity Monitor", true)
    DumpHtml(menuItems)

    -- BUT IMO is easier just to use elementSearch (which I bet is used under the hood here too on findMenuItem.. as does I bet getMenuItems use elementSearch, IIGC)
    -- DumpHtml(menuItems)

    -- PRN anything worth doing to enumerate the menus?
    -- for _, item in ipairs(menuItems) do
    --     -- local title = GetValueOrEmptyString(item)
    --     prints(hs.inspect(item), "<br>")
    -- end
end)


hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "M", function()
    -- USEFUL to quick check for a menu item
    -- TODO try axuielement.elementSearch and see how it compares vs this... (should have more attribute info avail)
    --   - IIAC it might find more menus (i.e. context  menus?)
    -- TODO for each menu item => generate AppleScript or hammerspoon lua code to invoke this menu item?
    -- FYI could use this to replace app - Paletro

    ensureClearedWebView()

    local app = hs.application.frontmostApplication()
    print("starting potentially slow element search of: " .. app:name())
    -- FYI can use app:getMenuItems(callback) instead (called when done, non-blocking too) - callback gets same object and then the return here is the app object (when cb provided)
    local menuItems = app:getMenuItems()
    -- timings:
    --  41ms (feels super fast) with hammerspoon's menus (~120 entries) at least
    --  can be slow with more menu items (i.e. FCPX)

    -- Dump(menuItems)
    DumpHtml(menuItems)

    -- PRN anything worth doing to enumerate the menus?
    -- for _, item in ipairs(menuItems) do
    --     -- local title = GetValueOrEmptyString(item)
    --     prints(hs.inspect(item), "<br>")
    -- end
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "E", function()
    -- test drive element search
    -- TODO try menu item search (like app.getMenuItems() above)

    ensureClearedWebView()

    local app = hs.application.frontmostApplication()
    DumpHtml(app)
    local appElement = hs.axuielement.applicationElement(app)

    local function testBuildTree()
        local start_time = GetTime()
        -- wow this is everything on the Hammerspoon app (all nested windows) and it took < 500ms until callback and then <200ms to display (of which some is probably lag to render page or to start rendering it?)
        -- serializing all the output to HTML was not at all expensive <200ms part!
        --   objectOnly=false (default with buildTree) means axuielement is transformed into a table (per element) and that means the
        --     I was worried attribute lookup would be super slow (like in Script Debugger's explorer)... but it seems like that isn't the case, necessarily ...
        --       !!! WHICH means SEARCH is viable to find and build scripts for me!!!
        -- WOW FCPX everything is 2672.4ms ... and that's with transform to tables!!!wow...that is the craziest app I have used for elements
        --
        appElement:buildTree(function(message, results)
            prints("time to callback: " .. GetElapsedTimeInMilliseconds(start_time) .. " ms")
            start_time = GetTime() -- reset

            prints("message: " .. message)
            if message ~= "completed" then
                print("SOMETHING WENT WRONG b/c message is not 'completed'")
            end
            print(hs.inspect(results))
            prints("results: ", InspectHtml(results))

            -- leave timing info in here b/c I will be running into more complex test cases and I wanna understand the overall timinmg implications of some of the apps I use
            prints("time to display: " .. GetElapsedTimeInMilliseconds(start_time) .. " ms")
        end)
    end
    testBuildTree()

    local start_time = GetTime()

    local function afterSearch(message, searchTask, numResultsAdded)
        -- numResultsAdded is the number of results added to the searchTask since elementSearch/next called (not overall #)
        -- FYI if you pass namedModifiers = { count: 3 } then it "pauses" search if you will and calls this callback and then you can resume with results:next() here, and then this callback is invoked after 3 more items are found, and you can continue until all elements are searched
        --    result object has cumulative results across each search run
        --    use this to build a more interactive/responsive search experience
        prints("time to callback: " .. GetElapsedTimeInMilliseconds(start_time) .. " ms")
        start_time = GetTime() -- reset

        prints("message: " .. message)
        if message ~= "completed" then
            print("SOMETHING WENT WRONG b/c message is not 'completed'")
        end
        prints("numResultsAdded: " .. numResultsAdded)
        prints("matched: " .. searchTask:matched())
        local results = searchTask -- just a reminder, enumerate the task (result) to get items
        prints("results: ", InspectHtml(results))

        -- leave timing info in here b/c I will be running into more complex test cases and I wanna understand the overall timinmg implications of some of the apps I use
        prints("time to display: " .. GetElapsedTimeInMilliseconds(start_time) .. " ms")
    end
    local function testElementSearchWithFilter()
        -- searchCriteriaFunction takes same arg as matchCriteria:
        --  www.hammerspoon.org/docs/hs.axuielement.html#matchesCriteria
        --  => single string (AXRole) matches exactly
        -- local elementCriteria = "AXWindow"
        --  => array table of strings (AXRole)
        -- local elementCriteria = { "AXWindow" }
        -- local elementCriteria = { "AXMenuItem" } -- 300ms to callback, 70ms to display with InspectHTML - Hammerspoon => 230 menu item matches
        --
        -- filter on common roles for menu type elements:
        --  - FYI value has the string, key is int, so have to filter/map on value
        local elementCriteria = EnumTableValues(hs.axuielement.roles):filter(function(e) return string.find(e, "Menu") end):totable()
        --
        -- local elementCriteria = { "AXButton", "AXRadioButton", "AXPopUpButton", "AXMenuButton" } -- ~300ms callback, 3.7ms to display (FYI I
        -- FYI when I re-run this shortcut (2nd time+) it takes 6.7 seconds to run elementSearch! ODD?! but reload hammerspoon config (wipes out state) and its back down to 300ms!
        --  => table of key/value pairs
        --  => array table of key/value pairs (logical AND of all criteria)
        prints("elementCriteria:", InspectHtml(elementCriteria))

        -- this is a function builder that IIAC transforms the elementCriteria into element API calls
        local criteriaFunction = hs.axuielement.searchCriteriaFunction(elementCriteria)


        local namedModifiers = nil -- optional settings
        -- local namedModifiers = { count = 3 } -- TODO try this with nested element, use to show progress updates after each X items and then call resume
        local searchTask = appElement:elementSearch(afterSearch, criteriaFunction, namedModifiers)
        -- CAN check progress/cancel/see results even with searchTask outside of the callback
    end
    -- testElementSearchWithFilter()


    local function testMyOwnFilterFunction()
        local function myFilterFunction(element)
            -- SKY IS THE LIMIT HERE
            -- wow checking both role (all elements have role) and title on all matching AXMenuItems (>200)... takes no more or less time in fact its takeing 260ms (hammerspoon full app/windows/) for the callback to start! that is 80-100ms less than using the above filters, why?
            -- WOW I CAN ENUMERATE EVERYTHING AND FIND WHAT I WANT... SO DARN COOL... even better if I have a way to take the frontmost app and the primary/main window.. that can help chisel away at extra stuff to avoid enumerating... I love it!
            -- WOW FCPX time to callback is 1739.8ms for everything! that is not at all bad... so why is Script Debugger so damn slow then?/
            local role = element:attributeValue("AXRole")
            if role and role ~= "AXMenuItem" then
                local title = element:attributeValue("AXTitle")
                if title and title ~= "" then
                    return true
                end
            end

            return false
        end

        local searchTask = appElement:elementSearch(afterSearch, myFilterFunction)
    end
    -- testMyOwnFilterFunction()
end)

local function combineClausesWithLineContinuations(clauses)
    -- assumes this is one set of clauses for a single line of code
    -- and that I can use a line continuation between any of the consecutive clauses
    --  - i.e. won't result in line continuation in the middle of a string literal
    local lines = EnumTableValues(clauses)
        :foldl(function(accum, current)
            local last = accum[#accum]
            if string.len(last) + string.len(current) > 80 then
                table.insert(accum, current)
                -- FYI don't forget return has to come last in a block (obscure detail I wanted to write down one time)
                return accum
            end
            accum[#accum] = last .. current
            return accum
        end, { "" })

    return table.concat(lines, "¬\n    ") -- four spaces on ident too
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "A", function()
    -- [A]ppleScript
    -- FYI "A" is easy to invoke with left hand alone (after position mouse with right--trackpad)
    -- reserve "I" for some other inspect mode? maybe to toggle mouse inspect mode

    ensureClearedWebView()

    -- TODO use elementSearch to find and build the applescript for a control, take in a string of text and go! its fast...
    --    consider using this to find an element if the original specifier chain stops working... and to have it spit out again a new chain?
    --    or even better if I switch to hammerspoon and have code that uses this accessibility API (much more predictable this way)... that can activate based on a fallback search... and update the specifier if it finds it with new one.. all  transparent for the user
    --      and/or could just cache a control first time shortcut key is used... until hammerspoon is reloaded (one time hit to find vs brittle specifiers => could be a trade off when to use which)
    --      would be neat to make more robust and just know how to do stuff so I can spend even less time thinking
    --    b/c I suspect if I have a unique-ish description (on buttons, text box) then I can always find that control w/ element search and the path/chain is not that mission critical other than the only way to write AppleScript (easily)
    --    remember I don't need AppleScript anymore, I can use axuielement in hammerspoon
    --          OR USE AXUIElement in python with pyobjc which I know that well too
    -- TODO build a tree of entire main/focused window using buildTree (or elementSearch)... it is super fast and would be cool to explore it like UI Browser has
    --

    local coords = hs.mouse.absolutePosition()
    -- FYI systemElementAtPosition(coords) => hs.axuielement.systemWideElement():elementAtPosition(coords)
    --   alternatively, could use an app element and ask for its elementAtPosition specific to just that app
    local elementAt = hs.axuielement.systemElementAtPosition(coords)
    -- DumpAXAttributes(elementAt, skipAttrsWhenInspectForPathBuilding)
    local clauses, attrDumps = BuildAppleScriptTo(elementAt, true)
    local script = combineClausesWithLineContinuations(clauses)
    prints("<pre><code class=\"language-applescript\">" .. script .. "</code></pre>")
    DumpAXActions(elementAt)
    DumpAXPath(elementAt, true)
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
    local subrole = GetValueOrEmptyString(elem, "AXSubrole")
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

    -- TODO fallback to whose on AXDescription? if avail? would need intermediate references... can I inline those?
    -- 	-- todo try inline nested refs:
    --      set sg2 to first splitter group of (first splitter group of window 1 of application process "Script Debugger" whose it is it)
    --      of course, `it is it` s/b a useful boolean specifier

    local function preferTitleOverIndexSpecifier(asClass)
        -- FYI AXTitle is a proxy (often, always?) for the name of the element in AppleScript
        if title ~= "" then
            return asClass .. ' "' .. title .. '" of '
        end
        return asClass .. " " .. elemIndex .. " of "
    end

    -- FYI element specifier logic, my current understanding:
    --   `class index` or `class "name"` are the two primary specifiers to use
    --      can also filter with where/whose clause if I add parens to nest the specifier and target the desired element's attributes'
    --   `class` nor `name` are available via AXUIElement
    --      IIUC these are synthesized... but I have not yet found an explanation of the synthesis logic
    --      `class` often matches `AXRoleDescription` but not always
    --      `class` can easily be mapped (so far no conflicts) to a hard coded value based on AXRole (below)
    --      `class` can also be `UI element` as a generic placeholder for any AXRole
    --   `name` often matches `AXTitle`
    --      but, IIRC, that is not always the case (that said, I have not encountered any issues yet where title != name, when I used title below)
    --      name might also be based on `AXDescription`, need to find examples to affirm/reject this possibility
    --   PRN I can add some fallback logic to synthesize name/class (when issues arise)
    --      PRN for class => use `osacompile` to check for compile error (will catch invalid class values)
    --      PRN for name => use `osascript` to see if element specifier works to get reference (or at least the generated AppleScript doesn't blow up)
    --        would need to find an example where the fallback logic then detects the next possible name for the specifier... not sure this will even be a thing
    --   `index` instead of using `name` use `index`, i.e. `window 1 of` or `first window of`
    --   where/whose
    --      Some issues may be resolved by looking at AXSubrole and using an attribute filter:
    --      i.e.:
    --         `set win to first window of proc whose value of attribute "AXSubrole" is "AXStandardWindow"`
    --      nested whose/where that works (both are same but one uses AXRole attr vs role property):
    --         set directLink to first UI element of (first UI element of (group 10 of ¬
    -- 	           application process "Brave Beta") whose value of attribute "AXRole" is equal to "AXHeading")
    --         set directLinkRole to first UI element of (first UI element of (group 10 of ¬
    -- 	           application process "Brave Beta") whose role is equal to "AXHeading")
    --
    if role == "AXWindow" then
        warnOnEmptyTitle(title, role)
        -- TODO handle duplicate titles (windows) => revert to use index?
        -- FYI title is an issue in some scenarios (i.e. if title is based on current document, like in Script Debugger)
        -- PRN consider using AXSubrole  (i.e. AXStandardWindow) as a filter too? get index relative to it?
        return 'window "' .. title .. '" of '
    elseif role == "AXBrowser" then
        -- FYI Finder columns view uses browser control:
        --    FYI finder example had issues when I used the title of "", whereas index worked
        return "browser " .. elemIndex .. " of "
    elseif role == "AXButton" then
        -- FYI UI Browser - tested a button with title as name and it worked! lets just wait and see if I encounter any issues...
        --    if issues arise... then how about switch to: `whose value of attribute "AXTitle" is __`
        --    FYI button in hierarchy is almost always gonna be the control at the bottom... just FYI
        --    could use tested fallback too or just show multiple options for button if last elem?
        return preferTitleOverIndexSpecifier("button")
    elseif role == "AXScrollBar" then
        return "scroll bar " .. elemIndex .. " of "
    elseif role == "AXMenuBar" then
        -- s/b fine to use index here.. esp b/c menu item would have title as name
        return "menu bar " .. elemIndex .. " of "
    elseif role == "AXTextField" then
        return "text field " .. elemIndex .. " of "
    elseif role == "AXScrollArea" then
        return "scroll area " .. elemIndex .. " of "
    elseif role == "AXSplitter" then
        return "splitter " .. elemIndex .. " of "
    elseif role == "AXSplitGroup" then
        return "splitter group " .. elemIndex .. " of "
    elseif role == "AXToolbar" then
        return "toolbar " .. elemIndex .. " of "
    elseif role == "AXTextArea" then
        return "text area " .. elemIndex .. " of "
    elseif role == "AXIncrementor" then
        return "incrementor " .. elemIndex .. " of "
    elseif role == "AXPopover" then
        return "pop over " .. elemIndex .. " of "
    elseif role == "AXPopUpButton" then
        return "pop up button " .. elemIndex .. " of "
    elseif role == "AXList" then
        -- TODO I might have had a special case of AXSubrole == "AXSectionList" ... and then used "section 1" instead of "list 1" (find and repro if so)
        if subrole == "AXSectionList" then
            prints("WARNING: AXSubrole is AXSectionList, using 'list' but might need 'section' instead? double check and then update this warning in code and change if needed")
        end
        return "list " .. elemIndex .. " of "
    elseif role == "AXCell" then
        return "cell " .. elemIndex .. " of "
    elseif role == "AXStaticText" then
        return "static text " .. elemIndex .. " of "
    elseif role == "AXRadioButton" then
        return "radio button " .. elemIndex .. " of "
    elseif role == "AXMenuItem" then
        -- FCPX show captions menu item (in expanded menu)
        -- set Show_Captions to menu item 37 of menu 1 of menu button 1 of group 1 of group 4 of splitter group 1 of group 2 of splitter group 1 of group 1 of splitter group 1 of window "Final Cut Pro" of application process "Final Cut Pro"
        -- FCPX menu to open first:
        --    	set View to menu button 1 of group 1 of group 4 of splitter group 1 of group 2 of splitter group 1 of group 1 of splitter group 1 of window "Final Cut Pro" of application process "Final Cut Pro"
        --      suggest: 	click View
        --      suggest: before that, activate FCPX and tell block Sys Events around it all
        --      ALSO: in the case of a menu item, to click it in this way, we should recommend opening the menu first (so find its menu parend generate a click on it + delay 0.1... yes!)
        --      ALSO: is it sometimes possible to click the menu items even if menu isn't visible and if that is the case (confirmed in code) can we prefer that first?
        -- TODO use preferTitle in other places (as it makes sense)
        return preferTitleOverIndexSpecifier("menu item")
    elseif role == "AXMenuButton" then
        return preferTitleOverIndexSpecifier("menu button")
    elseif role == "AXGroup" then
        -- FYI AXGroup in powerpoint fill color picker in Format Background tab has roleDescription == "Pane" and that did not work to select the item b/c it became "pane 1" and only "group 1" works
        --   I am not sure if that is a one off or if others fail like this...
        --   I did notice the AXName works with 'group "Format Background"' so maybe try that
        --   and in other cases w/ roleDescription default below, maybe name should be tried?
        --      TODO try "group \"" .. name .. "\" of "
        --      WAIT I DON'T have NAME like in Script Debugger... is that not available or is it smth that hammerspoon would need to fetch too? it is not an attribute BTW... it is smth else (like class)
        --         I am starting to suspect in most cases name == title (not always IIRC) but it has worked several times for windows
        --         PRN look into if hammerspoon could get name/class from Accessibility APIs or if that is some other construct in applescript that is not available
        --             dont forget I can always build nested () with where/whose clauses for each element (at all levels)
        -- !!! TODO find a way to test a reference before suggesting it? might slow things down but I should consider that...  and use a fallback strategy until something works... need some sort of builder that can test top to bottom elements and at each level have fallback and warn if nothing works
        --
        return "group " .. elemIndex .. " of "
    elseif role == "AXCheckBox" then
        -- FYI in powerpoint, color picker dropper button is subrole=AXToggle + roleDesc == "toggle button" but "toggle button 1" doesn't work.. put it back to "checkbox 1" and that worked
        return "checkbox " .. elemIndex .. " of "
    elseif role == "AXWebArea" then
        -- brave browser had one of these, "web area 1" does not work... generic works and in the case I found title == name
        return preferTitleOverIndexSpecifier("UI element")
    elseif role == "AXHeading" then
        -- BTW you could filter (whose) on UI element here.. though then I have to redo the clasuses thing :)... maybe? or have pairs of before/afterclauses
        -- AFAICT can only refer to it as "UI element"...
        --   can use title as name, at least in one test I did
        return preferTitleOverIndexSpecifier("UI element")
    elseif role == "AXTabGroup" then
        -- confirmed, see separate scpt files
        return "tab group " .. elemIndex .. " of "
    elseif role == "AXTable" then
        -- confirmed, see separate scpt files
        return "table " .. elemIndex .. " of "
    elseif role == "AXRow" then
        -- confirmed, see separate scpt files
        return "row " .. elemIndex .. " of "
    elseif role == "AXCell" then
        -- not working in current example (tested w/ AXTable/AXRow both of which worked :<)
        -- TODO why didn't `cell 1` work? (for html page table cell)
        return "UI element " .. elemIndex .. " of "
    elseif role == "AXLink" then
        -- not working as "link 1", use generic
        return "UI element " .. elemIndex .. " of "
    end
    prints("SUGGESTION: using roleDescription \"" .. roleDescription .. "\" as class (error prone in some cases), add an explicit mapping for AXRole: " .. role)
    -- FYI pattern, class == roleDesc - AX => split on captial letters (doesn't work for AXApplication, though actually it probably does work as ref to application class in Standard Suite?
    return roleDescription .. " " .. elemIndex .. " of "
end

function getIdentifier(toElement)
    local identifier = GetValueOrEmptyString(toElement, "AXTitle")
    if identifier == "" then
        identifier = GetValueOrEmptyString(toElement, "AXDescription")
    end
    if identifier == "" then
        -- prepend "_" b/c role description often overlaps with class (and cannot use that as name)
        identifier = "_" .. GetValueOrEmptyString(toElement, "AXRoleDescription")
    end
    if identifier == "" then
        -- TODO does this make sense, ever?
        -- FYI I don't recall seeing AXIdentifier on leaf level ui elements... usually up the chain in a split group
        --   FYI I bet this would change across diff configs of the app so not likely wise beyond current session... that's fine
        identifier = GetValueOrEmptyString(toElement, "AXIdentifier")
    end
    -- TODO last fallback to AXRole? and prepend _?
    if identifier == "" then
        prints("cannot determine an identifier, using foo")
        identifier = "foo"
    end
    -- todo ensure not reserved word:
    local appleScriptReservedWords = { "length", "if", "then", "else", "end", "repeat",
        "until", "for", "in", "do", "while", "function", "local", "return", "break",
        "goto", "and", "or", "not", "true", "false" }
    if EnumTableValues(appleScriptReservedWords):any(function(word) return word == identifier end) then
        -- alternatively I could put _ on the front of all generated identifiers... so I always know when it was a name I made vs actual keywords
        identifier = "_" .. identifier
    end
    return identifier
end

function BuildAppleScriptTo(toElement, includeAttrDumps)
    includeAttrDumps = includeAttrDumps or false

    local specifierChain = {}
    local attrDumps = {}
    -- REMEMBER toElement is last item in :path() list/table so dont need special handling for it outside of list
    for _, elem in pairs(toElement:path()) do
        if includeAttrDumps then
            -- for testing, don't even run this if not needed (has to have a good perf hit)
            local attrDump = GetDumpAXAttributes(elem, skipAttrsWhenInspectForPathBuilding)
            table.insert(attrDumps, attrDump)
        end

        table_prepend(specifierChain, elementSpecifierFor(elem))
    end

    -- IDEAS:
    --   return intermediate references too (for each level, or notable level, i.e. sg1, sg2, sg3, sa4, etc)
    --     consider variable name based on AXIdentifier (if other options fail)

    -- TODO use description if not title?
    -- TODO hungarian notation if title/desc are "too short" or?
    -- TODO build up some test cases would be helpful as you encounter real work examples
    local variableName = applescriptIdentifierFor(getIdentifier(toElement))
    -- return "<br>set " .. variableName .. " to " .. specifierChain, attrDumps
    local setCommand = "set " .. variableName .. " to "
    table_prepend(specifierChain, setCommand)

    -- FYI I could change the result to have more than one element item per specifierChain location (IOTW list of lists)...
    --   then could combine items at each location... so if two options in one location => then two final scripts
    --   two options w/ two each => 4 combinations
    return specifierChain, attrDumps
    -- PRN add suggestions section for actions to use and properties to get/set? as examples to copy/pasta
    --    i.e. text area => get/set value, button =>click
end

function BuildActionExamples(element)
    local actionNames = element:actionNames()
    -- element:actionDescriptions() => IIAC these work to invoke some actions
    return table.concat(actionNames, ", ")
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
        if userdata.__name == "hs.axuielement.axtextmarker"
            or userdata.__name == "hs.axuielement.axtextmarkerrange" then
            -- FYI nothing material to show, also don't wanna risk slowing anything down to get length/content (bytes).. unless that is useful and right now I don't think it is
            return tostring(userdata)
        end
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
        result = '## ACTIONS:<br>'
        for _, action in ipairs(actions) do
            -- FYI probably don't need description in most cases, only for custom app specific actions
            local description = element:actionDescription(action)
            result = result .. action .. ': ' .. description .. '<br>'
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
    if value == nil then
        return ""
    end
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

    return "<tr><td>" ..
        col1 ..
        "</td><td>" ..
        role ..
        "</td><td>" ..
        details .. "</td><td><code class='language-applescript'>" .. elementSpecifierFor(elem) .. "</code></td></tr>"
end

local pathTableStart = [[
<table class="path">
    <tr>
        <th>PATH</th>
        <th>role</th>
        <th>details</th>
        <th>specifier</th>
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
