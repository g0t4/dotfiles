local M = {}

-- TODO ... how about I format preceding user message and assistant response with the examples?! or would that bias some way toward the current conversation?
--   systemMessage
--   user: sample1
--   assistant: sample1Response
--   user: current question


-- TODO review and apply advice from Llama 4 about System Prompts (a few paragraphs down)
--   https://github.com/meta-llama/llama-models/blob/main/models/llama4/MODEL_CARD.md#model-level-fine-tuning

local devtoolsSystemMessage = [[
You are a chrome devtools expert.
The user is working in the DevTools Console in the Brave Beta Browser.
The user needs help completing a javascript command.
Whatever they have typed into the Console's command line will be provided to you.
Respond with valid javascript code. The code will replace what the user typed.
No explanation. No markdown. No markdown with backticks ` nor ```.

For example, the user might type:
  get the time in UTC
Your response could be:
  new Date().toISOString()

Or the user might ask:
  find the div with style color red
Your response could be:
  Array.from(document.querySelectorAll("div")).find(x => x.style.color === "red")
]]


-- issue => adding extra `end` after all completions (on own line)
local applescriptSystemMessage = [[
You are an AppleScript expert.
The user is working in Script Debugger or Script Editor.
The user selected part of their script that they want to provide to you for help.
Respond with valid AppleScript code.
Your response will replace what they selected.
Your responpse can include new lines if you have multiple lines.
Comments are ok, but only if absolutely necessary.
No explanation. No markdown. No markdown with backticks ` nor ```.

For example, the user might type:
  hello world notification
Your response could be:
  display notification "hello world" with title "example"
]]


local excelSystemMessage = [[
You are a excel expert.
The user is working in Excel.
The user needs help completing a formula or something else to do with excel.
Whatever they have typed into the Excel cell will be provided to you.
They might also have a free-form question included.
Respond with a single, valid excel formula. Their cell contents will be replaced with your response. So they can review and use it.
Make sure to include the = sign if you are suggesting a formula.
No explanation. No markdown. No markdown with backticks ` nor ```.

For example, the user might type:
  day of the week for cell A2
Your response could be:
  =TEXT(A2,"dddd")
]]

local hammerspoonSystemMessage = [[
The user is typing lua code in the Hammerspoon Console, basically a lua REPL.
Whatever code they have so far is provided.
Your response will replace their code.
Respond with valid lua code.
Prefer a single line of lua code (avoid newline).
No explanation. No markdown. No backticks ` nor ```.
]]

local omniBarSystemMessage = [[
You are a brave browser omnibar autocompletion engine.
Expert search engine that can vividly recall links.
The user is working in Brave Browser.
The user needs help in the omnibar.
Whatever they have typed into the Omni Bar will be provided to you.
Respond with a valid link or search text to submit to a search engine. Prefer a link if you know what they want.
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
-- unique ref: app:window_by_title('Hammerspoon docs: hs.hotkey - Brave Beta - wes private')
--   :group('Hammerspoon docs: hs.hotkey - Brave Beta - wes private'):group(''):group(''):group(''):toolbar(''):group('')
--   :textField('')
--


function M.getAppSpecificParams(app, focusedElem)
    local name = app:name()

    if name == APPS.BraveBrowserBeta then
        local desc = focusedElem:attributeValue('AXDescription')
        if desc and string.lower(desc) == 'address and search bar' then
            return { systemMessage = omniBarSystemMessage, max_tokens = 150 }
        end

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
