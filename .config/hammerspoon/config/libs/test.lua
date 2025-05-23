-- THIS FILE IS NOT IMPORTED and run automatically, just a scratchpad

-- FYI this is a list of reminders for 3rd party funcs I can be using
-- that I already setup, leave examples I can stumble on if I start
-- searching (b/c I might not have used them somewhere else yet)
-- For example, today I wanted string split, and I telescope searched
-- for "split\(" and found nothing... if this is here I'll find it next time.

-- * fnutils.split(string, separator) exists!
--   https://www.hammerspoon.org/docs/hs.fnutils.html
local fnutils = require("hs.fnutils")
for i, v in ipairs(fnutils.split(package.path, ";")) do print(i, v) end

-- * vim.iter!
local iter = require("config.libs.vim.iter")
local test = iter({ 1, 2, 3, 4, 5 }):map(function(v) return v * 3 end):rev():skip(2):totable()

print(test)


-- * axbrowse from asmagill
local axbrowse = require("config.libs.asmagill.axbrowse")
axbrowse.browse(hs.axuielement.applicationElement(hs.application("Final Cut Pro")))
-- VERY COOL, need to learn more ...
--  I wish it would highlight the current item in the app
--  I wish it would load the entire app tree of controls to fuzzy search all of them!
--  I wish it would stay open when I switch away, so I can come back
--    otherwise every time I have to manually recall and navigate the control heirarchy
--      my picker solved this by allowing me to point too
-- TODO try hs.chooser!


-- * inspectors
local inspectors = require("config.libs.asmagill.inspectors")
print(hs.inspect(inspectors))


-- * hs.noises
-- FYI, again, import so type hints work, else won't on things like :start() below
local hs_noises = require("hs.noises")
-- using hs.noises global provides some type hints
--  but nowhere near as complete as what you get with require'd modules
--  IIRC someone had to add the hs.noises global type hints via "definition" files
--
-- https://www.hammerspoon.org/docs/hs.noises.html
local handler = hs_noises.new(function(noise_type) print("noise type", noise_type) end)
handler:start()
