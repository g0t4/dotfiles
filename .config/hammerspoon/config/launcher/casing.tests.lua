if not vim.fn.getcwd():match("%.config/hammerspoon$") then
    error("\n\n*** CURRENT DIRECTORY IS NOT INSIDE hammerspoon config, require calls in tests won't work...\n\n\tuse `cd $WES_DOTFILES/.config/hammerspoon && nvim`)\n\n")
end
require("config.tests.setup")
local should = require('devtools.tests.should')
local describe = require('devtools.tests.define.describe')
local only = require('devtools.tests.define.only')
local skip = require('devtools.tests.define.skip')
local log = require("config.logs").hammerspoons()

local casing = require("config.launcher.casing")

describe("sentence_case", function()
    describe("change case", function()
        it("first word is uppercase", function()
            should.be_equal(casing.sentence_case("this is a test"), "This is a test")
        end)
        it("not first word is lowercase", function()
            should.be_equal(casing.sentence_case("The Cat Ran Into A Bus"), "The cat ran into a bus")
        end)
    end)

    describe("as-is", function()
        describe("if all uppercase letters then leave as-is (assume acronym)", function()
            -- I shouldn't need to register all acronyms
            it("first word", function()
                should.be_equal(casing.sentence_case("NASA ran a test"), "NASA ran a test") -- first word
            end)
            it("middle word", function()
                should.be_equal(casing.sentence_case("We had NASA run a test"), "We had NASA run a test") -- middle word
            end)
            it("last word", function()
                should.be_equal(casing.sentence_case("They ran a test with NASA"), "They ran a test with NASA") -- last word
            end)
            it("except single character words like 'A' which should be lowercase", function()
                should.be_equal(casing.sentence_case("This is Not A Test"), "This is not a test")
            end)
            -- TODO am I missing a ton of examples of words that are 2+ chars that I would want lowercase if not first word or explicitly perserved?
            -- TODO or can I generalize to a better rule: if any char after first is capitalized, then leave word as-is?
            --  is there ever a time when a general word would be CamelCase if start of sentence but then pascalCase in middle (or smth else like that if not cameal/pascal word cased)
        end)

        describe("preserve words that are a verbatim match (case sensitive) in preserve_words", function()
            -- keep them exactly as-is if they match exactly
            it("first word", function()
                should.be_equal(casing.sentence_case("VirtualBox is great"), "VirtualBox is great")
            end)
            it("middle word", function()
                should.be_equal(casing.sentence_case("I love VirtualBox daily"), "I love VirtualBox daily")
            end)
            it("last word", function()
                should.be_equal(casing.sentence_case("I love VirtualBox"), "I love VirtualBox")
            end)
        end)
    end)

    -- PRN add tests of multiple sentences in one... I won't be using this anytime soon.
end)
