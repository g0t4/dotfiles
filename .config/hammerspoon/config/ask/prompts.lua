local M = {}

-- TODO inject name of browser (if it were to matter), i.e. User Agent? ... can probably query that from AppleScript
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

function M.getPrompt(app)
    local name = app:name()

    if name == "Brave Browser Beta" then
        return { systemMessage = devtoolsSystemMessage, max_tokens = 200 }
    end

    if name == "Script Debugger" or name == "Script Editor" then
        -- TODO would it be useful to differentiate Script Debugger vs Script Editor
        --   i.e. the former has better debug tools so might want diff prompt to elucidate setting variables to inspect in Explorer view vs using logs in Script Editor
        -- try a smidge more for getting code blocks (I noticed that often it stops early b/c runs out of tokens)
        return { systemMessage = applescriptSystemMessage, max_tokens = 300 }
    end

    if name == "Microsoft Excel" then
        -- 200 is more than plenty for an excel formula
        return { systemMessage = excelSystemMessage, max_tokens = 200 }
    end

    return nil
end

return M
