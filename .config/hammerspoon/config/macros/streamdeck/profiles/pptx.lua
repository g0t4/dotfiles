local AppObserver = require("config.macros.streamdeck.profiles.appObserver")
local MaestroButton = require("config.macros.streamdeck.maestroButton")
local KeyStrokeButton = require("config.macros.streamdeck.keystrokeButton")
local verbose = require("config.macros.streamdeck.helpers").verbose
local MenuButton = require("config.macros.streamdeck.menuButton")
local LuaButton = require("config.macros.streamdeck.luaButton")


-- !!! TODO app observer for shapes and other types... activate different buttons (or behaviors) based on the current seleted shape

local PptxObserver = AppObserver:new("Microsoft PowerPoint")

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
        -- * row 1 (buttons 1-8)
        LuaButton:new(1, deck, hsIcon("pptx/shapes/align-left.png"), menu({ "Arrange", "Align or Distribute", "Align Left" })),
        LuaButton:new(2, deck, hsIcon("pptx/shapes/align-center.png"), menu({ "Arrange", "Align or Distribute", "Align Center" })),
        LuaButton:new(3, deck, hsIcon("pptx/shapes/align-right.png"), menu({ "Arrange", "Align or Distribute", "Align Right" })),
        MaestroButton:new(4, deck, hsIcon("pptx/arrange/alignment-objects.png"), "14B23130-38EC-4510-BFE9-557900E13DF6"),
        LuaButton:new(5, deck, hsIcon("pptx/shapes/distribute-vertical.png"), menu({ "Arrange", "Align or Distribute", "Distribute Vertically" })),
        LuaButton:new(6, deck, hsIcon("pptx/shapes/distribute-horizontal.png"), menu({ "Arrange", "Align or Distribute", "Distribute Horizontally" })),
        KeyStrokeButton:new(7, deck, hsIcon("pptx/arrange/hotkey-group-60x60.png"), { "cmd", "shift" }, ","),
        LuaButton:new(8, deck, hsIcon("pptx/shapes/align-top.png"), menu({ "Arrange", "Align or Distribute", "Align Top" })),

        -- * row 2 (buttons 9-16)
        KeyStrokeButton:new(9, deck, hsIcon("pptx/arrange/hotkey-ungroup-60x60.png"), { "cmd", "shift" }, "/"),
        MaestroButton:new(10, deck, hsIcon("pptx/picture/resize-plus-one-percent.png"), "FC2D2B91-F5C3-4C83-9A5D-CEB00CE09D8F"),
        MaestroButton:new(11, deck, hsIcon("pptx/picture/resize-minus-one-percent.png"), "485063B6-14C6-400F-9BA0-130628467342"),
        MaestroButton:new(12, deck, hsIcon("pptx/transitions/transitions-morph-objects.png"), "A6B90E50-C53C-44F4-98C4-F8E5059074CA"),
        MaestroButton:new(13, deck, hsIcon("pptx/picture/change-picture-maintain-size.png"), "7FE31128-978B-4693-B531-B6BDA2C053DE"),
        MaestroButton:new(14, deck, hsIcon("pptx/picture/change-picture-to-20-percent.png"), "4EF6A3FB-CC2F-4CA2-A936-BDDF7D90F626"),
        MaestroButton:new(15, deck, hsIcon("pptx/format/format-shape-fill-line.png"), "63CCD7EB-BB4B-4555-BAF1-D3C0D6034450"),
        LuaButton:new(16, deck, hsIcon("pptx/shapes/align-middle.png"), menu({ "Arrange", "Align or Distribute", "Align Middle" })),

        -- * row 3 (buttons 17-24)
        LuaButton:new(17, deck, hsIcon("pptx/shapes/flip-vertical.png"), menu({ "Arrange", "Rotate or Flip", "Flip Vertical" })),
        LuaButton:new(18, deck, hsIcon("pptx/shapes/flip-horizontal.png"), menu({ "Arrange", "Rotate or Flip", "Flip Horizontal" })),
        LuaButton:new(19, deck, hsIcon("pptx/shapes/rotate-left-90.png"), menu({ "Arrange", "Rotate or Flip", "Rotate Left 90°" })),
        LuaButton:new(20, deck, hsIcon("pptx/shapes/rotate-right-90.png"), menu({ "Arrange", "Rotate or Flip", "Rotate Right 90°" })),
        MaestroButton:new(21, deck, hsIcon("pptx/format/format-shape-size-rotation.png"), "0B2D06E8-F001-425E-BB7E-646DB84342D8"),
        MaestroButton:new(22, deck, hsIcon("pptx/format/format-picture-crop.png"), "A2CAB0BB-5B91-4040-9C5C-E9355F26FA2B"),
        MaestroButton:new(23, deck, hsIcon("pptx/format/copy-format.png"), "219BB69A-9C8A-4378-BACE-5AD6B84331DF"),
        LuaButton:new(24, deck, hsIcon("pptx/shapes/align-bottom.png"), menu({ "Arrange", "Align or Distribute", "Align Bottom" })),

        -- * row 4 (buttons 25-32)
        KeyStrokeButton:new(25, deck, hsIcon("pptx/arrange/bring-to-front-60x60.png"), { "cmd", "shift" }, "f"),
        KeyStrokeButton:new(26, deck, hsIcon("pptx/arrange/send-forward-60x60.png"), { "cmd", "alt", "shift" }, "f"),
        KeyStrokeButton:new(27, deck, hsIcon("pptx/arrange/send-backward-60x60.png"), { "cmd", "alt", "shift" }, "b"),
        KeyStrokeButton:new(28, deck, hsIcon("pptx/arrange/send-to-back-60x60.png"), { "cmd", "shift" }, "b"),
        MaestroButton:new(29, deck, hsIcon("pptx/animation/animation-painter.png"), "082B06B7-0846-4981-98F5-0920C4C93CDA"),
        MaestroButton:new(30, deck, hsIcon("pptx/animation/toggle-animation-pane.png"), "5F3CF10D-FA52-4DD0-AF84-6A0CF443ECF3"),
        MaestroButton:new(31, deck, hsIcon("pptx/animation/toggle-selection-pane.png"), "E1ED7FC7-FF68-44CC-82F2-4725B34B9E8D"),
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
