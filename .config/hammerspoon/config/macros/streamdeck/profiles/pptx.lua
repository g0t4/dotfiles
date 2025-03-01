local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local CommandButton = require("config.macros.streamdeck.commandButton")
local verbose = require("config.macros.streamdeck.helpers").verbose
local MenuButton = require("config.macros.streamdeck.menuButton")
local LuaButton = require("config.macros.streamdeck.luaButton")
require("config.macros.streamdeck.iconHelpers")


-- !!! TODO app observer for shapes and other types... activate different buttons (or behaviors) based on the current seleted shape


function openPath(path)
    return function()
        -- TODO how do I wanna deal with spaces? Is this fine:
        runCommand("open '" .. path .. "'")
    end
end

local PptxObserver = AppObserver:new("Microsoft PowerPoint")


-- Example CommandButton:
--         CommandButton:new(32, deck, hsIcon("files/movies-dir-elgato72.png"), { "open", "~/Movies2" }),

PptxObserver:addProfilePage(DECK_1XL, PAGE_1, function(_, deck)
    return {
        -- * row 1 (buttons 1-8)
        MaestroButton:new(4, deck, hsIconWithText("pptx/recording/start-recording.png", "Start\nRecording", deck, SmallText), "2C964DF9-0831-432B-94FE-124D43593C02"),
        MaestroButton:new(5, deck, hsIcon("pptx/recording/stop-recording.png"), "662A956C-CC67-499B-AEB5-C36D59E5BA3F"),
        -- TODO look into profile addons (for private buttons, i.e. don't want action in my dotfiles repo)

        -- * row 2 (buttons 9-16)
        MaestroButton:new(9, deck, hsIconWithText("pptx/utilities/restart-powerpoint.png", "Restart\nPowerPoint", deck, SmallText), "340FAC91-F2D0-4C13-94CB-64492671B5CE"),
        MaestroButton:new(11, deck, hsIcon("pptx/ribbon/slide-layout.png"), "B436C96B-4A24-494C-A221-C7572633E631"),
        MaestroButton:new(12, deck, hsIcon("pptx/ribbon/section-expand.png"), "7A072785-AD96-4750-8B3C-9E8C7D7A8878"),
        MaestroButton:new(13, deck, hsIcon("pptx/ribbon/section-collapse.png"), "A20F3F91-C284-4CCE-8E1C-EF64E4513C11"),
        MaestroButton:new(14, deck, hsIconWithText("pptx/tabs/wes-tab.png", "\nWES", deck, MediumText), "C9E06D7C-63AA-4729-BFE1-B8140E89F2DE"),
        MaestroButton:new(15, deck, hsIconWithText("pptx/tabs/shape-format-tab.png", "\nShape\nFormat", deck, SmallText), "C9E06D7C-63AA-4729-BFE1-B8140E89F2DE", "Shape Format"),
        MaestroButton:new(16, deck, hsIconWithText("pptx/tabs/animations-tab.png", "\nAnim\nations", deck, SmallText), "C9E06D7C-63AA-4729-BFE1-B8140E89F2DE", "Animations"),

        -- * row 3 (buttons 17-24)
        MaestroButton:new(17, deck, hsIcon("pptx/layouts/hide-thumbnails.png"), "D848AD00-9FBC-4770-A12A-2552D0BE51F5"),
        MaestroButton:new(18, deck, hsIcon("pptx/layouts/small-thumbnails.png"), "E1DD6FDE-DDDC-4D78-A722-E6C4613D89A9"),
        MaestroButton:new(19, deck, hsIcon("pptx/layouts/medium-thumbnails.png"), "B61C9924-66AE-43BA-9EC1-C90CA40CBB80"),
        MaestroButton:new(20, deck, hsIcon("pptx/layouts/hide-side-panes.png"), "0B9F4515-6A58-4A17-8447-BE5FA15D1266"),
        MaestroButton:new(21, deck, hsIcon("pptx/layouts/hide-right-pane.png"), "A5E648CD-4064-482F-9412-F91D4420664A"),

        -- * row 4 (buttons 25-32)
        MaestroButton:new(32, deck, hsIconWithText("pptx/utilities/export-thumb.png", "Export\nThumb", deck, MediumText), "3721DD9F-A02C-4293-B2DF-982FBFCFEBC7"),
    }
end)

PptxObserver:addProfilePage(DECK_2XL, PAGE_1, function(_, deck)
    return {


        -- * row 4
        LuaButton:new(32, deck, pageRightImage(deck), changePage(DECK_2XL, "pptx", PAGE_2)),

    }
end)

PptxObserver:addProfilePage(DECK_2XL, PAGE_2, function(_, deck)
    return {
        -- * row 1

        -- * row 4
        LuaButton:new(25, deck, pageLeftImage(deck), changePage(DECK_2XL, "pptx", PAGE_1)),

    }
end)


PptxObserver:addProfilePage(DECK_3XL, PAGE_1, function(_, deck)
    return {
        -- TODO verify button names are appropriate (the ones claude moved, I did pptx/shapes)
        -- * row 1 (buttons 1-8)
        LuaButton:new(1, deck, hsIcon("pptx/shapes/align-left.png"), menu({ "Arrange", "Align or Distribute", "Align Left" })),
        LuaButton:new(2, deck, hsIcon("pptx/shapes/align-center.png"), menu({ "Arrange", "Align or Distribute", "Align Center" })),
        LuaButton:new(3, deck, hsIcon("pptx/shapes/align-right.png"), menu({ "Arrange", "Align or Distribute", "Align Right" })),
        MaestroButton:new(4, deck, hsIconWithText("pptx/arrange/alignment-objects.png", "\nAlign Objects", deck, SmallText), "14B23130-38EC-4510-BFE9-557900E13DF6"),
        LuaButton:new(5, deck, hsIcon("pptx/shapes/distribute-vertical.png"), menu({ "Arrange", "Align or Distribute", "Distribute Vertically" })),
        LuaButton:new(6, deck, hsIcon("pptx/shapes/distribute-horizontal.png"), menu({ "Arrange", "Align or Distribute", "Distribute Horizontally" })),
        LuaButton:new(8, deck, hsIcon("pptx/shapes/align-top.png"), menu({ "Arrange", "Align or Distribute", "Align Top" })),

        -- * row 2 (buttons 9-16)
        KeyStrokeButton:new(9, deck, hsIcon("pptx/arrange/hotkey-group-60x60.png"), { "cmd", "shift" }, ","),
        KeyStrokeButton:new(10, deck, hsIcon("pptx/arrange/hotkey-ungroup-60x60.png"), { "cmd", "shift" }, "/"),
        MaestroButton:new(11, deck, hsIcon("pptx/picture/resize-plus-one-percent.png"), "FC2D2B91-F5C3-4C83-9A5D-CEB00CE09D8F"),
        MaestroButton:new(12, deck, hsIcon("pptx/picture/resize-minus-one-percent.png"), "485063B6-14C6-400F-9BA0-130628467342"),
        MaestroButton:new(13, deck, hsIcon("pptx/transitions/transitions-morph-objects.png"), "A6B90E50-C53C-44F4-98C4-F8E5059074CA"),
        MaestroButton:new(14, deck, hsIcon("pptx/picture/change-picture-maintain-size.png"), "7FE31128-978B-4693-B531-B6BDA2C053DE"),
        MaestroButton:new(15, deck, hsIcon("pptx/picture/change-picture-to-20-percent.png"), "4EF6A3FB-CC2F-4CA2-A936-BDDF7D90F626"),
        LuaButton:new(16, deck, hsIcon("pptx/shapes/align-middle.png"), menu({ "Arrange", "Align or Distribute", "Align Middle" })),

        -- * row 3 (buttons 17-24)
        LuaButton:new(17, deck, hsIcon("pptx/shapes/flip-vertical.png"), menu({ "Arrange", "Rotate or Flip", "Flip Vertical" })),
        LuaButton:new(18, deck, hsIcon("pptx/shapes/flip-horizontal.png"), menu({ "Arrange", "Rotate or Flip", "Flip Horizontal" })),
        LuaButton:new(19, deck, hsIcon("pptx/shapes/rotate-left-90.png"), menu({ "Arrange", "Rotate or Flip", "Rotate Left 90°" })),
        LuaButton:new(20, deck, hsIcon("pptx/shapes/rotate-right-90.png"), menu({ "Arrange", "Rotate or Flip", "Rotate Right 90°" })),
        MaestroButton:new(21, deck, hsIcon("pptx/format/format-shape-fill-line.png"), "63CCD7EB-BB4B-4555-BAF1-D3C0D6034450"),
        MaestroButton:new(22, deck, hsIcon("pptx/format/format-shape-size-rotation.png"), "0B2D06E8-F001-425E-BB7E-646DB84342D8"),
        MaestroButton:new(23, deck, hsIcon("pptx/format/format-picture-crop.png"), "A2CAB0BB-5B91-4040-9C5C-E9355F26FA2B"),
        LuaButton:new(24, deck, hsIcon("pptx/shapes/align-bottom.png"), menu({ "Arrange", "Align or Distribute", "Align Bottom" })),

        -- * row 4 (buttons 25-32)
        KeyStrokeButton:new(25, deck, hsIconWithSmallBlackText("pptx/arrange/bring-to-front-60x60.png", "\nFront", deck), { "cmd", "shift" }, "f"),
        KeyStrokeButton:new(26, deck, hsIcon("pptx/arrange/send-forward-60x60.png"), { "cmd", "alt", "shift" }, "f"),
        KeyStrokeButton:new(27, deck, hsIcon("pptx/arrange/send-backward-60x60.png"), { "cmd", "alt", "shift" }, "b"),
        KeyStrokeButton:new(28, deck, hsIcon("pptx/arrange/send-to-back-60x60.png"), { "cmd", "shift" }, "b"),
        MaestroButton:new(29, deck, hsIcon("pptx/format/copy-format.png"), "219BB69A-9C8A-4378-BACE-5AD6B84331DF"),
        MaestroButton:new(30, deck, hsIcon("pptx/animation/animation-painter.png"), "082B06B7-0846-4981-98F5-0920C4C93CDA"),
        MaestroButton:new(31, deck, hsIcon("pptx/animation/toggle-animation-pane.png"), "5F3CF10D-FA52-4DD0-AF84-6A0CF443ECF3"),
        MaestroButton:new(32, deck, hsIcon("pptx/animation/toggle-selection-pane.png"), "E1ED7FC7-FF68-44CC-82F2-4725B34B9E8D"),
        -- Button 32 is not used in the original profile
    }
end)

PptxObserver:addProfilePage(DECK_4PLUS, PAGE_1, function(_, deck)
    return {
        -- *** row 1

        -- *** row 2
    }
end)


return PptxObserver
