local M = {}

-- TODO ok FYI some reason chunk processing is not quite working ... esp if the chunk contains {} curly braces... otherwise seems to work fine...
--    TODO develop a way to log the entire response so I can review it (to a file is gonna be best)... just the raw response is gonna be best me thinks
local devtoolsSystemMessage = [[
You are a chrome devtools expert.
The user is working in the devtools Console in the Brave Beta Browser.
The user needs help completing a javascript command.
Whatever they have typed into the Console's command line will be provided to you.
They might also have a free-form question included, i.e. in a comment (after //).
Respond with a single, valid javascript command line. Their command line will be replaced with your response. So they can review and execute it.
No explanation. No markdown. No markdown with backticks ` nor ```.

An example of a command line could be `find the first div on the page` and a valid response would be `document.querySelector('div')`
]]


-- issue => adding extra `end` after all completions (on own line)
local applescriptSystemMessage = [[
You are an AppleScript expert.
The user is working in Script Debugger or Script Editor.
The user needs help completing statement(s) or something else about AppleScript.
The user selected part of their script that they want to provide to you for help.
If you see a comment prefixed by `-- help ...` without the backticks, that is the question/request and the rest is the relevant existing script code. Do whatever is asked in the comment in this case (i.e. modify the rest of the code).
Respond with valid AppleScript statement(s).
Your response will replace what they selected. So they can review and use it.
Your responpse can include new lines if you have multiple lines.
Comments are ok, only if absolutely necessary.
No explanation. No markdown. No markdown with backticks ` nor ```.
]]


local excelSystemMessage = [[
You are a excel expert.
The user is working in Excel.
The user needs help completing a formula or something else to do with excel.
Whatever they have typed into the Excel cell will be provided to you.
They might also have a free-form question included.
Respond with a single, valid excel formula. Their cell contents will be replaced with your response. So they can review and use it.
No explanation. No markdown. No markdown with backticks ` nor ```.

An example of a question could be `= sum up H4:H8` and a valid response would be `= SUM(H4:H8)`. Make sure to include the = sign if you are suggesting a formula.
]]

local hammerspoonSystemMessage = [[
The user is typing lua code in the Hammerspoon Console, basically a lua REPL.
Whatever code they have so far is provided.
Your response will replace their code.
Respond with valid lua code.
No explanation. No markdown. No backticks ` nor ```.
]]

-- TODO Brave now I wanna target the addy bar sep of devtools!
--   PUT AI WHERE IT WAS DESIGNED TO BELONG... in your search engine (addy bar) ***! ... private search if offline model :)
--   imagine being able to ask a question about where to go for a website and have it answer without even searching!
--   yes, I know omnibar mostly does that but there are plenty of times when it sucks at that!
--
-- *IMPL: Look at AXDescription? or otherwise:
-- app:window(1):group(1):group(1):group(1):group(1):toolbar(1):group(1):textField(1)
--
-- most likely:
-- AXDescription: Address and search bar<string>
-- AXDOMClassList: [1: BraveOmniboxViewViews<string>]
--
-- AXAutocompleteValue: both<string>
-- AXBlockQuoteLevel: 0<number>
-- AXEditableAncestor: AXTextField '' - Address and search bar<hs.axuielement>
-- AXElementBusy: false<bool>
-- AXEnabled: true<bool>
-- AXFocusableAncestor: AXTextField '' - Address and search bar<hs.axuielement>
-- AXFocused: true<bool>
-- AXHighestEditableAncestor: AXTextField '' - Address and search bar<hs.axuielement>
-- AXInvalid: false<string>
-- AXKeyShortcutsValue: ⌘L<string>
-- AXPlaceholderValue: Search Brave or type a URL<string>
-- AXRequired: false<bool>
-- AXRoleDescription: text field<string>
-- AXSelected: false<bool>
-- AXSelectedRows: []
-- AXSelectedText: https://www.hammerspoon.org/docs/hs.hotkey.html#bind<string>
-- AXValue: https://www.hammerspoon.org/docs/hs.hotkey.html#bind<string>
-- AXVisited: false<bool>
-- ChromeAXNodeId: 58972<string>
--
-- unique ref: app:window('Hammerspoon docs: hs.hotkey - Brave Beta - wes private')
--   :group('Hammerspoon docs: hs.hotkey - Brave Beta - wes private'):group(''):group(''):group(''):toolbar(''):group('')
--   :textField('')
--


function M.getPrompt(app, focusedElem)
    local name = app:name()

    if name == APPS.BraveBrowserBeta then
        return { systemMessage = devtoolsSystemMessage, max_tokens = 200 }
    end

    if name == "Script Debugger" or name == "Script Editor" then
        -- TODO would it be useful to differentiate Script Debugger vs Script Editor
        --   i.e. the former has better debug tools so might want diff prompt to elucidate setting variables to inspect in Explorer view vs using logs in Script Editor
        -- try a smidge more for getting code blocks (I noticed that often it stops early b/c runs out of tokens)
        return { systemMessage = applescriptSystemMessage, max_tokens = 300 }
    end

    if name == APPS.Excel then
        -- 200 is more than plenty for an excel formula
        return { systemMessage = excelSystemMessage, max_tokens = 200 }
    end
    if name == APPS.Hammerspoon then
        -- PRN double check its the Console window?
        return { systemMessage = hammerspoonSystemMessage, max_tokens = 200 }
    end

    return nil
end

return M
