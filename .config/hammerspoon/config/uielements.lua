local fun = require "fun"
local print_web_view = nil
local print_web_window = nil
local print_html_buffer = {}
local print_web_view_user_content_controller = nil
local html_page

-- TODO RENAME TO SNAKE_CASE IN LUA - should just need to do global functions used/defined in this file

local skip_attrs_when_inspect_for_path_building = {
    -- PRN truncate long values instead? could pass max length here
    AXTopLevelUIElement = true,
    AXWindow = true,
    AXParent = true,
}

local function read_entire_file(config_relative_path)
    local full_path = hs.configdir .. "/" .. config_relative_path
    local file = io.open(full_path, "r")

    if not file then
        error("Unable to read file: " .. full_path)
        return nil
    end

    local contents = file:read("*a")
    file:close()
    return contents
end

local function prints(...)
    -- PRN www.jstree.com - if I want a tree view that has collapsed sections that hide details initially ... only use this if use case arises from daily use... my hope is generated AppleScript works most of the time
    for _, arg in ipairs({ ... }) do
        if print_web_view == nil then
            -- if no web view to print to, then print to console

            -- user visible line break == <br>, html src line break == \n
            --   this replace with \n for all line breaks when printing to console
            arg = arg:gsub("<br>", "\n")
            -- PRN strip table tags too?
            print(arg)
        else
            if type(arg) == "string" then
                arg = arg:gsub("\t", "&nbsp;&nbsp;")
                table.insert(print_html_buffer, arg)
            elseif type(arg) == "number" then
                table.insert(print_html_buffer, tostring(arg))
            else
                print("WARN: unexpected prints arg type: " .. type(arg))
                table.insert(print_html_buffer, tostring(arg))
            end
        end
    end
    if print_web_view then
        if not html_page then
            -- basically the <head> section with js/css, don't worry about proper body ... just print after this
            html_page = read_entire_file("config/uielements.html")
            if not html_page then
                html_page = "<h1>FAILED TO LOAD uielements.html</h1>"
            end
        end
        local html = html_page .. table.concat(print_html_buffer, "<br/>")
        print_web_view:html(html)
    end
end

function print_to_web_view(...)
    prints(...)
end

local function ensure_web_view()
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
    local half_width = frame.w / 2
    local midX = half_width + frame.x
    -- FYI assumes frame might not start at 0,0
    if mouseAt.x < midX then
        -- mouse is on left side of screen, show webview on right side
        rect = hs.geometry.rect(midX, frame.y, half_width, frame.h)
        -- print("right rect:", hs.inspect(rect))
    else
        -- mouse is on right, show webview on left
        rect = hs.geometry.rect(frame.x, frame.y, half_width, frame.h)
        -- print("left rect:", hs.inspect(rect))
    end

    if print_web_view == nil then
        -- how to make sure not a new tab in previous browser webview instance?

        -- Enable inspect element (and thus dev tools) in the webview
        --    right click to inspect
        --    FYI more preferencesTable options: https://www.hammerspoon.org/docs/hs.webview.html#new
        --    USE THIS TO TEST JS FIRST!
        local prefs = { ["developerExtrasEnabled"] = true }

        print_web_view_user_content_controller = require("hs.webview.usercontent").new("testmessageport")

        local js_code = read_entire_file("config/uielements.js")
        print_web_view_user_content_controller:injectScript({ source = js_code })


        print_web_view = require("hs.webview").newBrowser(rect, prefs, print_web_view_user_content_controller)

        -- webview:url("https://google.com")
        print_web_view:windowTitle("Inspector")
        print_web_view:show()
        print_web_window = print_web_view:hswindow()
        print_web_view:titleVisibility("hidden")

        print_web_view:windowCallback(function(action, _, _)
            -- FYI 2nd arg is webview, 3rd arg is state/frame (depending on action type)
            if action == "closing" then
                print_web_view = nil
                print_web_view_user_content_controller = nil
                print_web_window = nil
            end
        end)
    else
        -- PRN ensure not minimized
        -- PRN ensure on top w/o modal
        -- right now lets leave it alone if it still exists, that way I can hide it if I don't want it on top
        --   might be useful to have it in background until I capture the element I want and then I can switch to it
    end
    if not print_web_window then
        prints("no webview window, aborting")
        return
    end
    print_web_view:frame(rect)
    print_web_window:raise() -- ensure on top for Hammerspoon app
    print_web_window:application():activate() -- ensure Hammerspoon app is front most too (else all app windows remain in the background)
end


function inspect_html(value, completed)
    completed = completed or {}

    local is_build_tree_table_of_ax_ui_element = type(value) == "table" and value["_element"]
    local reference_name = ""
    if is_build_tree_table_of_ax_ui_element then
        -- PRN add back:
        --    type(value) == "userdata" or
        --    IF AND WHEN I add _inspectUserData pathway that recursively calls inspect_html (for some child attr/property)
        --
        -- don't repeat showing same objects (userdata, or tables of axuielement info from buildTree)
        -- FYI do not ban all dup tables b/c then coordinates are a mess for example, will only show first time
        if completed[value] then
            reference_name = type(value) .. completed[value]
            return "<span style='color:red'>Repeated #" .. reference_name .. "</span>"
        end

        -- this way I can use the index into completed tabl as an identifier to know which is the first time it was dumped
        local completed_number = completed.nextNumber or 1 -- track # as extra field so it is passed too (effectively by ref)
        completed[value] = completed_number
        completed.nextNumber = completed_number + 1
        reference_name = type(value) .. completed_number -- so I can link back to the first time the reference is displayed, in future occurences
        -- prints(referenceName)
    end

    local function _inspectTable(tbl)
        -- helper only for InspectHTML, don't use this directly
        -- FYI I like that this prints each level (unlike hs.inspect which consolidates tables with one item in them,  mine shows the actual index of each, within each table)
        local html = "<ul>"
        if reference_name ~= "" then
            -- show right before the table's nested list (ul)
            html = reference_name .. "<ul>"
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
            html = html .. string.format("<li>%s: %s</li>", hs.inspect(k), inspect_html(v, completed))
            -- end
        end
        return html .. "</ul>"
    end

    local function _inspect_user_data(userdata)
        local userdata_type = userdata["__type"] -- nil if not set (i.e. non hammerspoon userdata types)
        if userdata_type == "hs.axuielement" then
            local ax_type = userdata["AXRole"] or ""
            local ax_title = WrapInQuotesIfNeeded(userdata["AXTitle"])
            local ax_desc = WrapInQuotesIfNeeded(userdata["AXDescription"])
            -- FYI in this case, do not show hs.axuielement b/c AX* indicates that already so save the space
            return string.format("%s %s %s %s", reference_name, ax_type, ax_title, ax_desc)
        elseif userdata_type == "hs.application" then
            local app_name = userdata:name()
            local app_bundle_id = userdata:bundleID()
            -- in this case, app name alone isn't enough of hint so show the type 'hs.application'
            return string.format("hs.application(%s) - %s %s", reference_name, app_name, app_bundle_id)
        end

        -- TODO handle other hammerspoon userdata types
        return reference_name .. hs.inspect(userdata) .. " - TODO add this hs type to inspectHTML"
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
        return _inspect_user_data(value)
    else
        return hs.inspect(value)
    end
end

function dump_html(value)
    prints(inspect_html(value))
end

function ensure_cleared_web_view()
    if print_web_view then
        print_html_buffer = {}
    end
    ensure_web_view()
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "S", function()
    -- [S]earch menu items

    ensure_cleared_web_view()

    local app = hs.application.frontmostApplication()
    print("starting potentially slow element search of: " .. app:name())

    local menu_items = app:findMenuItem("Activity Monitor", true)
    dump_html(menu_items)

    -- BUT IMO is easier just to use elementSearch (which I bet is used under the hood here too on findMenuItem.. as does I bet getMenuItems use elementSearch, IIGC)
    -- dump_html(menu_items)

    -- PRN anything worth doing to enumerate the menus?
    -- for _, item in ipairs(menu_items) do
    --     -- local title = get_value_or_empty_string(item)
    --     prints(hs.inspect(item), "<br>")
    -- end
end)


hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "M", function()
    -- USEFUL to quick check for a menu item
    -- FYI could use this to replace app - Paletro (use canvas to draw menu control)

    ensure_cleared_web_view()

    local app = hs.application.frontmostApplication()
    print("starting potentially slow element search of: " .. app:name())
    -- FYI can use app:getMenuItems(callback) instead (called when done, non-blocking too) - callback gets same object and then the return here is the app object (when cb provided)
    local menu_items = app:getMenuItems()
    -- timings:
    --  41ms (feels super fast) with hammerspoon's menus (~120 entries) at least
    --  can be slow with more menu items (i.e. FCPX)

    -- Dump(menu_items)
    dump_html(menu_items)

    -- PRN anything worth doing to enumerate the menus?
    -- for _, item in ipairs(menu_items) do
    --     -- local title = get_value_or_empty_string(item)
    --     prints(hs.inspect(item), "<br>")
    -- end
end)


hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "E", function()
    -- test drive element search
    -- TODO try menu item search (like app.getMenuItems() above)

    ensure_cleared_web_view()

    local app = hs.application.frontmostApplication()
    dump_html(app)
    ---@type hs.axuielement
    local app_element = hs.axuielement.applicationElement(app)

    local function test_build_tree()
        local start_time = get_time()
        -- wow this is everything on the Hammerspoon app (all nested windows) and it took < 500ms until callback and then <200ms to display (of which some is probably lag to render page or to start rendering it?)
        -- serializing all the output to HTML was not at all expensive <200ms part!
        --   objectOnly=false (default with buildTree) means axuielement is transformed into a table (per element) and that means the
        --     I was worried attribute lookup would be super slow (like in Script Debugger's explorer)... but it seems like that isn't the case, necessarily ...
        --       !!! WHICH means SEARCH is viable to find and build scripts for me!!!
        -- WOW FCPX everything is 2672.4ms ... and that's with transform to tables!!!wow...that is the craziest app I have used for elements
        --
        app_element:buildTree(function(message, results)
            prints("time to callback: " .. get_elapsed_time_in_milliseconds(start_time) .. " ms")
            start_time = get_time() -- reset

            prints("message: " .. message)
            if message ~= "completed" then
                print("SOMETHING WENT WRONG b/c message is not 'completed'")
            end
            print(hs.inspect(results))
            prints("results: ", inspect_html(results))

            -- leave timing info in here b/c I will be running into more complex test cases and I wanna understand the overall timinmg implications of some of the apps I use
            prints("time to display: " .. get_elapsed_time_in_milliseconds(start_time) .. " ms")
        end)
    end
    -- test_build_tree()

    local start_time = get_time()

    local function after_search(message, search_task, num_results_added)
        -- numResultsAdded is the number of results added to the searchTask since elementSearch/next called (not overall #)
        -- FYI if you pass namedModifiers = { count: 3 } then it "pauses" search if you will and calls this callback and then you can resume with results:next() here, and then this callback is invoked after 3 more items are found, and you can continue until all elements are searched
        --    result object has cumulative results across each search run
        --    use this to build a more interactive/responsive search experience
        prints("time to callback: " .. get_elapsed_time_in_milliseconds(start_time) .. " ms")
        start_time = get_time() -- reset

        prints("message: " .. message)
        if message ~= "completed" then
            print("SOMETHING WENT WRONG b/c message is not 'completed'")
        end
        prints("numResultsAdded: " .. num_results_added)
        prints("matched: " .. search_task:matched())
        local results = search_task -- just a reminder, enumerate the task (result) to get items
        prints("results: ", inspect_html(results))

        -- leave timing info in here b/c I will be running into more complex test cases and I wanna understand the overall timinmg implications of some of the apps I use
        prints("time to display: " .. get_elapsed_time_in_milliseconds(start_time) .. " ms")
    end
    local function test_element_search_with_filter()
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
        local element_criteria = EnumTableValues(hs.axuielement.roles)
            :filter(function(e) return string.find(e, "Menu") end)
            :totable()
        --
        -- local elementCriteria = { "AXButton", "AXRadioButton", "AXPopUpButton", "AXMenuButton" } -- ~300ms callback, 3.7ms to display (FYI I
        -- FYI when I re-run this shortcut (2nd time+) it takes 6.7 seconds to run elementSearch! ODD?! but reload hammerspoon config (wipes out state) and its back down to 300ms!
        --  => table of key/value pairs
        --  => array table of key/value pairs (logical AND of all criteria)
        prints("element_criteria:", inspect_html(element_criteria))

        -- this is a function builder that IIAC transforms the elementCriteria into element API calls
        local criteria_function = hs.axuielement.searchCriteriaFunction(element_criteria)


        local named_modifiers = nil -- optional settings
        -- local namedModifiers = { count = 3 } -- TODO try this with nested element, use to show progress updates after each X items and then call resume
        local search_task = app_element:elementSearch(after_search, criteria_function, named_modifiers)
        -- CAN check progress/cancel/see results even with searchTask outside of the callback
    end
    test_element_search_with_filter()


    local function test_my_own_filter_function()
        local function my_filter_function(element)
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

        local search_task = app_element:elementSearch(after_search, my_filter_function)
    end
    -- test_my_own_filter_function()
end)

local function html_code_applescript(script)
    return "<code class='language-applescript'>" .. script .. "</code>"
end

local function html_code_lua(script)
    return "<code class='language-lua'>" .. script .. "</code>"
end

local function html_pre_code_applescript(script)
    return "<pre>" .. html_code_applescript(script) .. "</pre>"
end

local function html_pre_code_lua(script)
    return "<pre>" .. html_code_lua(script) .. "</pre>"
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "A", function()
    ensure_cleared_web_view()

    -- [A]ppleScript
    -- FYI "A" is easy to invoke with left hand alone (after position mouse with right--trackpad)
    -- reserve "I" for some other inspect mode? maybe to toggle mouse inspect mode

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

    local callouts = require("config.ui_callouts")
    local element_at = nil
    if callouts.moves then
        print("using last callout element for report")
        -- run dump on current element from callouts, this way I can nav around with arrows + pick parent elements that aren't selected by systemElementAtPosition, also children item sometimes aren't selected (i.e. SOM image buttons on toolbars)
        element_at = callouts.last.element
    else
        local coords = hs.mouse.absolutePosition()
        -- FYI systemElementAtPosition(coords) => hs.axuielement.systemWideElement():elementAtPosition(coords)
        --   alternatively, could use an app element and ask for its elementAtPosition specific to just that app
        element_at = hs.axuielement.systemElementAtPosition(coords)
    end
    local clauses, attr_dumps = build_applescript_to(element_at, true)
    local applescript = ConcatIntoLines(clauses, 80, "¬")
    prints(html_pre_code_applescript(applescript))
    local lua = BuildHammerspoonLuaTo(element_at)
    prints(html_pre_code_lua(lua))
    prints(BuildActionExamples(element_at))
    prints(GetDumpPath(element_at, true))
    prints(table.unpack(attr_dumps))
end)

-- see AppleScript The Definitive Guide, page 197 about Element Specifier forms (name, index, ID, some, every, range, relative, bool test [whose?],...?)
function element_specifier_for(elem)
    local function warn_on_empty_title(title, role)
        if title == "" then
            prints("[WARN] title is empty for " .. role .. ", script might not work")
        end
    end

    local role = get_value_or_empty_string(elem, "AXRole")
    local subrole = get_value_or_empty_string(elem, "AXSubrole")
    local role_description = get_value_or_empty_string(elem, "AXRoleDescription")
    local title = get_value_or_empty_string(elem, "AXTitle")
    if role == "AXApplication" then
        warn_on_empty_title(title, role)
        -- PRN if duplicated title, use AXParent to get other child windows?
        -- FYI AXApplication is the root most object, aka "object string specifier" (see Definitive Guide book, page 206-207)
        return 'application process "' .. title .. '"'
    end

    local elem_index = GetElementSiblingIndex(elem)
    if elem_index == nil then
        return " should not happen - failed to get sibling index for "
            .. role .. " " .. title
    end

    -- PRN fallback to whose on AXDescription? if avail? would need intermediate references... can I inline those?
    -- 	-- todo try inline nested refs:
    --      set sg2 to first splitter group of (first splitter group of window 1 of application process "Script Debugger" whose it is it)
    --      of course, `it is it` s/b a useful boolean specifier

    local function prefer_title_over_index_specifier(asClass)
        -- FYI AXTitle is a proxy (often, always?) for the name of the element in AppleScript
        if title ~= "" then
            return asClass .. ' "' .. title .. '" of '
        end
        return asClass .. " " .. elem_index .. " of "
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
        warn_on_empty_title(title, role)
        -- TODO handle duplicate titles (windows) => revert to use index?
        -- FYI title is an issue in some scenarios (i.e. if title is based on current document, like in Script Debugger)
        -- PRN consider using AXSubrole  (i.e. AXStandardWindow) as a filter too? get index relative to it?
        return 'window "' .. title .. '" of '
    elseif role == "AXBrowser" then
        -- FYI Finder columns view uses browser control:
        --    FYI finder example had issues when I used the title of "", whereas index worked
        return "browser " .. elem_index .. " of "
    elseif role == "AXButton" then
        -- FYI UI Browser - tested a button with title as name and it worked! lets just wait and see if I encounter any issues...
        --    if issues arise... then how about switch to: `whose value of attribute "AXTitle" is __`
        --    FYI button in hierarchy is almost always gonna be the control at the bottom... just FYI
        --    could use tested fallback too or just show multiple options for button if last elem?
        return prefer_title_over_index_specifier("button")
    elseif role == "AXScrollBar" then
        return "scroll bar " .. elem_index .. " of "
    elseif role == "AXMenuBar" then
        -- s/b fine to use index here.. esp b/c menu item would have title as name
        return "menu bar " .. elem_index .. " of "
    elseif role == "AXTextField" then
        return "text field " .. elem_index .. " of "
    elseif role == "AXScrollArea" then
        return "scroll area " .. elem_index .. " of "
    elseif role == "AXSplitter" then
        return "splitter " .. elem_index .. " of "
    elseif role == "AXSplitGroup" then
        return "splitter group " .. elem_index .. " of "
    elseif role == "AXToolbar" then
        return "toolbar " .. elem_index .. " of "
    elseif role == "AXTextArea" then
        return "text area " .. elem_index .. " of "
    elseif role == "AXIncrementor" then
        return "incrementor " .. elem_index .. " of "
    elseif role == "AXPopover" then
        return "pop over " .. elem_index .. " of "
    elseif role == "AXPopUpButton" then
        return "pop up button " .. elem_index .. " of "
    elseif role == "AXList" then
        -- TODO I might have had a special case of AXSubrole == "AXSectionList" ... and then used "section 1" instead of "list 1" (find and repro if so)
        if subrole == "AXSectionList" then
            prints("WARNING: AXSubrole is AXSectionList, using 'list' but might need 'section' instead? double check and then update this warning in code and change if needed")
        end
        return "list " .. elem_index .. " of "
    elseif role == "AXStaticText" then
        return "static text " .. elem_index .. " of "
    elseif role == "AXRadioButton" then
        return "radio button " .. elem_index .. " of "
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
        return prefer_title_over_index_specifier("menu item")
    elseif role == "AXMenuButton" then
        return prefer_title_over_index_specifier("menu button")
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
        return "group " .. elem_index .. " of "
    elseif role == "AXCheckBox" then
        -- FYI in powerpoint, color picker dropper button is subrole=AXToggle + roleDesc == "toggle button" but "toggle button 1" doesn't work.. put it back to "checkbox 1" and that worked
        return "checkbox " .. elem_index .. " of "
    elseif role == "AXWebArea" then
        -- brave browser had one of these, "web area 1" does not work... generic works and in the case I found title == name
        return prefer_title_over_index_specifier("UI element")
    elseif role == "AXHeading" then
        -- BTW you could filter (whose) on UI element here.. though then I have to redo the clasuses thing :)... maybe? or have pairs of before/afterclauses
        -- AFAICT can only refer to it as "UI element"...
        --   can use title as name, at least in one test I did
        return prefer_title_over_index_specifier("UI element")
    elseif role == "AXTabGroup" then
        -- confirmed, see separate scpt files
        return "tab group " .. elem_index .. " of "
    elseif role == "AXTable" then
        -- confirmed, see separate scpt files
        return "table " .. elem_index .. " of "
    elseif role == "AXRow" then
        -- confirmed, see separate scpt files
        return "row " .. elem_index .. " of "
    elseif role == "AXColumn" then
        -- confirmed, see separate scpt files
        return "column " .. elem_index .. " of "
    elseif role == "AXCell" then
        -- so, AXTable/Row/Column all work, so AXCell is just a standalone concept that intersects but doesn't have a class to correspond
        return "UI element " .. elem_index .. " of "
    elseif role == "AXLink" then
        -- not working as "link 1", use generic
        return "UI element " .. elem_index .. " of "
        -- TODO AXHelpTag (subrole AXUknown) => saw in brave browser when pointed at links, couldn't repo in Script Debugger though
    end
    prints("SUGGESTION: using roleDescription \"" .. role_description .. "\" as class (error prone in some cases), add an explicit mapping for AXRole: " .. role)
    -- FYI pattern, class == roleDesc - AX => split on captial letters (doesn't work for AXApplication, though actually it probably does work as ref to application class in Standard Suite?
    return role_description .. " " .. elem_index .. " of "
end

local function get_identifier(to_element)
    local identifier = get_value_or_empty_string(to_element, "AXTitle")
    if identifier == "" then
        identifier = get_value_or_empty_string(to_element, "AXDescription")
    end
    if identifier == "" then
        -- prepend "_" b/c role description often overlaps with class (and cannot use that as name)
        identifier = "_" .. get_value_or_empty_string(to_element, "AXRoleDescription")
    end
    if identifier == "" then
        -- TODO does this make sense, ever?
        -- FYI I don't recall seeing AXIdentifier on leaf level ui elements... usually up the chain in a split group
        --   FYI I bet this would change across diff configs of the app so not likely wise beyond current session... that's fine

        -- UMM... while testing FCPX (restarts, close panels and quit, reopen... AXIdentifier seems stable for at least this version?!
        --   # 10 (title inspect cbox), 18 (video), 21 (color), 24 (info), 84 (static text 1 - title bar on inspector panel)
        identifier = get_value_or_empty_string(to_element, "AXIdentifier")
    end
    -- TODO last fallback to AXRole? and prepend _?
    if identifier == "" then
        prints("cannot determine an identifier, using foo")
        identifier = "foo"
    end
    -- todo ensure not reserved word:
    local apple_script_reserved_words = { "length", "if", "then", "else", "end", "repeat",
        "until", "for", "in", "do", "while", "function", "local", "return", "break",
        "goto", "and", "or", "not", "true", "false" }
    if EnumTableValues(apple_script_reserved_words):any(function(word) return word == identifier end) then
        -- alternatively I could put _ on the front of all generated identifiers... so I always know when it was a name I made vs actual keywords
        identifier = "_" .. identifier
    end

    local function applescript_sanitize_identifier(text)
        -- Replace non-alphanumeric characters with underscores
        local identifier = text:gsub("%W", "_")
        -- Ensure the identifier starts with a letter or underscore
        if not identifier:match("^[a-zA-Z_]") then
            identifier = "_" .. identifier
        end
        return identifier
    end

    return applescript_sanitize_identifier(identifier)
end

function build_applescript_to(to_element, include_attr_dumps)
    include_attr_dumps = include_attr_dumps or false

    local specifier_chain = {}
    local attr_dumps = {}
    -- REMEMBER toElement is last item in :path() list/table so dont need special handling for it outside of list
    for _, elem in pairs(to_element:path()) do
        if include_attr_dumps then
            -- for testing, don't even run this if not needed (has to have a good perf hit)
            local attr_dump = GetDumpAXAttributes(elem, skip_attrs_when_inspect_for_path_building)
            table.insert(attr_dumps, attr_dump)
        end

        table_prepend(specifier_chain, element_specifier_for(elem))
    end

    -- IDEAS:
    --   return intermediate references too (for each level, or notable level, i.e. sg1, sg2, sg3, sa4, etc)
    --     consider variable name based on AXIdentifier (if other options fail)

    -- TODO use description if not title?
    -- TODO hungarian notation if title/desc are "too short" or?
    -- TODO build up some test cases would be helpful as you encounter real work examples
    local variable_name = get_identifier(to_element)
    -- return "<br>set " .. variable_name .. " to " .. specifierChain, attrDumps
    local set_command = "set " .. variable_name .. " to "
    table_prepend(specifier_chain, set_command)

    -- FYI I could change the result to have more than one element item per specifierChain location (IOTW list of lists)...
    --   then could combine items at each location... so if two options in one location => then two final scripts
    --   two options w/ two each => 4 combinations
    return specifier_chain, attr_dumps
    -- PRN add suggestions section for actions to use and properties to get/set? as examples to copy/pasta
    --    i.e. text area => get/set value, button =>click
end

function get_value_or_empty_string(element, attribute)
    local value = element:attributeValue(attribute)
    if value then
        return value
    else
        return ""
    end
end

function CompactUserData(userdata)
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
    local title = get_value_or_empty_string(userdata, "AXTitle")
    local role = get_value_or_empty_string(userdata, "AXRole")
    return title .. ' (' .. role .. ')'
end

function DisplayAttr(attr_value)
    if attr_value == nil then
        return 'nil'
    elseif type(attr_value) == "userdata" then
        return CompactUserData(attr_value)
    elseif type(attr_value) == "table" then
        -- i.e. AXSize, AXPosition, AXFrame, AXVisibleCharacterRange
        return CompactTableAttrValue(attr_value)
    elseif type(attr_value) == 'string' then
        return '"' .. attr_value .. '"'
    else
        return tostring(attr_value)
    end
end

function CompactTableAttrValue(tbl)
    if tbl == nil then
        return "nil"
    end
    local result = {}
    for attr_name, attr_value in pairs(tbl) do
        local display_value = DisplayAttr(attr_value)
        table.insert(result, string.format("%s=%s", tostring(attr_name), display_value))
    end

    return "{" .. table.concat(result, ", ") .. "}"
end

function GetDumpAXAttributes(element, skips)
    skips = skips or {}

    local result = { '<h4>' .. html_code_applescript(element_specifier_for(element)) .. '</h4>' }

    local sorted_attrs = {}
    for attr_name, attr_value in pairs(element) do
        -- TODO skip nil attrValue?
        if not skips[attr_name] then
            table.insert(sorted_attrs, attr_name)
        end
    end
    table.sort(sorted_attrs)
    for _, attr_name in ipairs(sorted_attrs) do
        local attr_value = element[attr_name]
        local display_name = attr_name
        local display_value = DisplayAttr(attr_value)
        if display_value == "nil" or display_value == '""' then
            table.insert(result, "\t<span class='not-set-attribute'>" .. display_name .. ' = ' .. display_value .. "</span><br>")
        else
            local display_name_class = string.lower(attr_name) -- used for styling important attributes (i.e. AXTitle)
            table.insert(result, "\t<span class='" .. display_name_class .. "'>" .. display_name .. ' = ' .. display_value .. "</span><br>")
        end
    end
    return table.concat(result)
end

function BuildActionExamples(element)
    local identifer = get_identifier(element)
    local actions = element:actionNames()
    local script = "" -- leave empty if none is likely fine
    if #actions > 0 then
        for _, action in ipairs(actions) do
            -- FYI probably don't need description in most cases, only for custom app specific actions
            -- local description = element:actionDescription(action)
            -- result = result .. action .. ': ' .. description .. '<br>'
            script = script .. "perform action \"" .. action .. "\" of " .. identifer .. "<br>"
        end
    end
    return html_pre_code_applescript(script)
end

function GetElementSiblingIndex(elem)
    local parent = elem:attributeValue("AXParent")
    if parent == nil then
        return nil
    end

    -- FYI! window index changes if you switch windows! or close them... i.e. in a browser, finder, etc

    -- how expensive is it to get the attribute value here (again)? same for AXParent above
    local role = get_value_or_empty_string(elem, "AXRole")
    local role_siblings = parent:childrenWithRole(role)
    local elem_index = 1
    if #role_siblings > 1 then
        for i, sibling in ipairs(role_siblings) do
            if sibling == elem then
                elem_index = i
            end
        end
    end
    return elem_index
end

---@param value string|nil # PRN accept any type not just string?
---@return string
function WrapInQuotesIfNeeded(value)
    if value == nil then
        return ""
    end
    return string.find(value, "%s") and '"' .. value .. '"' or value
end

---@param elem hs.axuielement
---@param indent boolean|nil # siblings/children are indented underneath path elements (aka toplevel)
---@return string
function GetElementTableRow(elem, indent)
    local role = get_value_or_empty_string(elem, "AXRole")
    local title = get_value_or_empty_string(elem, "AXTitle")
    local sub_role = get_value_or_empty_string(elem, "AXSubrole")
    local identifier = get_value_or_empty_string(elem, "AXIdentifier")
    -- PRN AXHelp?
    local description = get_value_or_empty_string(elem, "AXDescription")
    local role_description = get_value_or_empty_string(elem, "AXRoleDescription")
    local elem_index = GetElementSiblingIndex(elem) or ''

    local col1 = role_description .. ' ' .. elem_index
    if sub_role ~= "" then
        col1 = col1 .. ' (' .. sub_role .. ')'
    end
    if title ~= "" then
        col1 = col1 .. ' "' .. title .. '"'
    end

    local details = ""
    if description ~= "" and description ~= role_description then
        -- only show if AXRoleDescription doesn't already cover what AXDescription has
        details = details .. ' desc=' .. WrapInQuotesIfNeeded(description)
    end
    if identifier ~= "" then
        details = details .. ' id=' .. identifier
    end

    local row_class = indent and "indented" or "toplevel"
    return "<tr class='" .. row_class .. "'><td>" ..
        col1 ..
        "</td><td>" ..
        role ..
        "</td><td>" ..
        details .. "</td><td>" .. html_code_applescript(element_specifier_for(elem)) .. "</td></tr>"
end

-- PRN try to get nested @language annotations to work and provide syntax highlighting (etc) for nested language, i.e. html:
--    https://emmylua.github.io/annotations/language.html
---@language HTML
local path_table_start = [[
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
        local result = path_table_start
        for _, elem in ipairs(path) do
            local current = GetElementTableRow(elem)
            result = result .. current .. '\n' -- \n is for html formatting in src

            if expanded then
                local children = elem:attributeValue("AXChildren")
                if children == nil then
                    children = {}
                end
                for _, child in pairs(children) do
                    result = result .. GetElementTableRow(child, true) .. "\n"
                end
            end
        end
        result = result .. "</table>\n"
        return result
    else
        return "NO PATH - should not happen, even AXApplication (top level) has self as path"
    end
end
