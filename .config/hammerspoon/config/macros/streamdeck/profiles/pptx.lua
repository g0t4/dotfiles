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


PptxObserver:addProfilePage(DECK_1XL, PAGE_1, function(_, deck)
    return {
        -- TODO finish review of buttons and names (Claude started this whole page)

        -- * row 1 (buttons 1-8)
        MaestroButton:new(4, deck, hsIconWithText("pptx/recording/bmp-96/start-recording.png.bmp", "Start\nRecording", deck, SmallText), "2C964DF9-0831-432B-94FE-124D43593C02"),
        MaestroButton:new(5, deck, hsIcon("pptx/recording/bmp-96/stop-recording.png.bmp"), "662A956C-CC67-499B-AEB5-C36D59E5BA3F"),
        -- TODO show pptx file type icon? and then add text on bottom?
        MaestroButton:new(6, deck, hsIconWithText("pptx/utilities/bmp-96/ps-template.png.bmp", "Template", deck, SmallText), "7CA5817C-EAA6-45C2-B0C6-3CC7204B2E29"),
        -- TODO show generic folder icon?
        MaestroButton:new(7, deck, hsIcon("pptx/utilities/bmp-96/ps-icons.png.bmp"), "885C3710-A8BB-4280-9764-CD32A9B822A4"),

        -- * row 2 (buttons 9-16)
        MaestroButton:new(9, deck, hsIconWithText("pptx/utilities/bmp-96/restart-powerpoint.png.bmp", "Restart\nPowerPoint", deck, SmallText), "340FAC91-F2D0-4C13-94CB-64492671B5CE"),
        MaestroButton:new(11, deck, hsIcon("pptx/ribbon/bmp-96/slide-layout.png.bmp"), "B436C96B-4A24-494C-A221-C7572633E631"),
        MaestroButton:new(12, deck, hsIcon("pptx/ribbon/bmp-96/section-expand.png.bmp"), "7A072785-AD96-4750-8B3C-9E8C7D7A8878"),
        MaestroButton:new(13, deck, hsIcon("pptx/ribbon/bmp-96/section-collapse.png.bmp"), "A20F3F91-C284-4CCE-8E1C-EF64E4513C11"),
        MaestroButton:new(14, deck, hsIconWithText("pptx/tabs/bmp-96/wes-tab.png.bmp", "\nWES", deck, MediumText), "C9E06D7C-63AA-4729-BFE1-B8140E89F2DE"),
        MaestroButton:new(15, deck, hsIconWithText("pptx/tabs/bmp-96/shape-format-tab.png.bmp", "\nShape\nFormat", deck, SmallText), "C9E06D7C-63AA-4729-BFE1-B8140E89F2DE", "Shape Format"),
        MaestroButton:new(16, deck, hsIconWithText("pptx/tabs/bmp-96/animations-tab.png.bmp", "\nAnim\nations", deck, SmallText), "C9E06D7C-63AA-4729-BFE1-B8140E89F2DE", "Animations"),

        -- * row 3 (buttons 17-24)
        MaestroButton:new(17, deck, hsIcon("pptx/layouts/bmp-96/hide-thumbnails.png.bmp"), "D848AD00-9FBC-4770-A12A-2552D0BE51F5"),
        MaestroButton:new(18, deck, hsIcon("pptx/layouts/bmp-96/small-thumbnails.png.bmp"), "E1DD6FDE-DDDC-4D78-A722-E6C4613D89A9"),
        MaestroButton:new(19, deck, hsIcon("pptx/layouts/bmp-96/medium-thumbnails.png.bmp"), "B61C9924-66AE-43BA-9EC1-C90CA40CBB80"),
        MaestroButton:new(20, deck, hsIcon("pptx/layouts/bmp-96/hide-side-panes.png.bmp"), "0B9F4515-6A58-4A17-8447-BE5FA15D1266"),
        MaestroButton:new(21, deck, hsIcon("pptx/layouts/bmp-96/hide-right-pane.png.bmp"), "A5E648CD-4064-482F-9412-F91D4420664A"),

        -- * row 4 (buttons 25-32)
        MaestroButton:new(32, deck, hsIconWithText("pptx/utilities/bmp-96/export-thumb.png.bmp", "Export\nThumb", deck, MediumText), "3721DD9F-A02C-4293-B2DF-982FBFCFEBC7"),
    }
end)

PptxObserver:addProfilePage(DECK_2XL, PAGE_2, function(_, deck)
    -- FYI verified all are good from Claude migration
    return {

        -- TODO? make colors secondary pages, then when I get into context detection/observation, I can setup deck2 with contextual buttons (i.e. if color field then show color buttons, or shape selected then show outline buttons, etc)

        -- * row 1 (buttons 1-8)
        MaestroButton:new(1, deck, hsIcon("pptx/colors/bmp-96/fill-gray-dark.png.bmp"), "D2B20FA1-3564-4021-86CB-D94D08151BED"),
        MaestroButton:new(9, deck, hsIcon("pptx/colors/bmp-96/line-gray-dark.png.bmp"), "5B6621C7-D4F3-4602-9C3B-E8BC3C458C37"),
        MaestroButton:new(17, deck, hsIcon("pptx/colors/bmp-96/text-gray-dark.png.bmp"), "55278E01-CAE8-4E99-ACEE-2BDD7941A0DC"),
        MaestroButton:new(2, deck, hsIcon("pptx/colors/bmp-96/fill-gray-middle.png.bmp"), "FAC6E724-4481-4F68-8112-178042B43CB4"),
        MaestroButton:new(10, deck, hsIcon("pptx/colors/bmp-96/line-gray-middle.png.bmp"), "61EA278C-0DC9-46F3-939E-26EF933D2CBD"),
        MaestroButton:new(18, deck, hsIcon("pptx/colors/bmp-96/text-gray-middle.png.bmp"), "FEB8C424-5350-4B4B-8CDA-1291EAF13F01"),

        -- * row 2 (buttons 9-16)
        MaestroButton:new(3, deck, hsIcon("pptx/colors/bmp-96/fill-gray-light.png.bmp"), "F5AF89F1-2ACC-4272-BCAA-87106F78B11E"),
        MaestroButton:new(11, deck, hsIcon("pptx/colors/bmp-96/line-gray-light.png.bmp"), "5ED37CD2-669A-49B1-ABDC-03B1C42926A6"),
        MaestroButton:new(19, deck, hsIcon("pptx/colors/bmp-96/text-gray-light.png.bmp"), "813D28B3-9EFB-4871-ABA9-447FF9F848E1"),
        MaestroButton:new(4, deck, hsIcon("pptx/colors/bmp-96/fill-white.png.bmp"), "0604BF43-7965-4BDB-98C0-06A3017F2C4E"),
        MaestroButton:new(12, deck, hsIcon("pptx/colors/bmp-96/line-white.png.bmp"), "7EBFC5EC-7DC2-47B2-BDB0-81907ED745CD"),
        MaestroButton:new(20, deck, hsIcon("pptx/colors/bmp-96/text-white.png.bmp"), "FB59CAE0-092B-4793-887B-41D914EC4FC3"),

        -- * row 3 (buttons 17-24)

        -- * row 4 (buttons 25-32)
        LuaButton:new(32, deck, pageRightImage(deck), changePage(DECK_2XL, APPS.MicrosoftPowerPoint, PAGE_1, PptxObserver)),
    }
end)

PptxObserver:addProfilePage(DECK_2XL, PAGE_1, function(_, deck)
    -- TODO try using color background instead of images w/ hex values... check perf difference (if any)
    -- FYI verified these are good (except need to test actions on two marked below)
    --
    -- CONVERTED WITH:
    --   mkdir -p bmp-96; ls *.png | xargs -I_ sips -s format bmp _ --resampleHeightWidth  96 96  --out bmp-96/_.bmp
    --   w/o even adding caching BMPs shaved 10ms+ off of overall time to change to PPTX on 2XL deck (this one)

    return {
        MaestroButton:new(1, deck, hsIcon("pptx/colors/bmp-96/fill-pink.png.bmp"), "02BF881E-47AF-4812-830F-4765B6AABC41"),
        MaestroButton:new(9, deck, hsIcon("pptx/colors/bmp-96/line-pink.png.bmp"), "FBAD1498-E64F-4A26-8B41-59D4B59C4F6B"),
        MaestroButton:new(17, deck, hsIcon("pptx/colors/bmp-96/text-pink.png.bmp"), "F5068DE4-4EA3-4B4E-ABE9-44A358D380B1"),

        MaestroButton:new(2, deck, hsIcon("pptx/colors/bmp-96/fill-blue.png.bmp"), "D5CD851F-5A99-46E1-A922-4EF11726BD8A"),
        MaestroButton:new(10, deck, hsIcon("pptx/colors/bmp-96/line-blue.png.bmp"), "5250FA4D-74BE-4E29-8EFB-3F9DA4183923"),
        MaestroButton:new(18, deck, hsIcon("pptx/colors/bmp-96/text-blue.png.bmp"), "A8963B4C-825B-4BBC-9C4B-105B1FDBB253"),

        MaestroButton:new(3, deck, hsIcon("pptx/colors/bmp-96/fill-purple.png.bmp"), "EE2F4019-8615-4A6C-9CE8-840D9FA27778"),
        MaestroButton:new(11, deck, hsIcon("pptx/colors/bmp-96/line-purple.png.bmp"), "4AD5641B-4BAF-47D6-A6B8-D8D93041F23C"),
        MaestroButton:new(19, deck, hsIcon("pptx/colors/bmp-96/text-purple.png.bmp"), "09063A55-0CE1-4AE3-BAC2-8DF341AF619D"),

        MaestroButton:new(4, deck, hsIcon("pptx/colors/bmp-96/fill-yellow.png.bmp"), "70299E82-5094-44CD-98EB-EE783BE3FA0E"),
        MaestroButton:new(12, deck, hsIcon("pptx/colors/bmp-96/line-yellow.png.bmp"), "289D7C69-74B6-4127-B7EF-4C054EADD65E"),
        MaestroButton:new(20, deck, hsIcon("pptx/colors/bmp-96/text-yellow.png.bmp"), "E13771C5-F241-4C3A-8064-7765F6F30369"),

        MaestroButton:new(5, deck, hsIcon("pptx/colors/bmp-96/fill-orange.png.bmp"), "C4E8F125-C719-4125-A3A2-1492642DC054"),
        MaestroButton:new(13, deck, hsIcon("pptx/colors/bmp-96/line-orange.png.bmp"), "2AA28BE5-58A4-403C-8ABD-3FC69152E5B3"),
        MaestroButton:new(21, deck, hsIcon("pptx/colors/bmp-96/text-orange.png.bmp"), "F4CB8BE1-1199-4472-948F-07D5BBF11464"),

        MaestroButton:new(6, deck, hsIcon("pptx/colors/bmp-96/fill-green.png.bmp"), "EB427AC4-F6EE-4C4A-8972-47C7D91F1C92"),
        MaestroButton:new(14, deck, hsIcon("pptx/colors/bmp-96/line-green.png.bmp"), "D1E5B8B5-3160-4FF7-B6F3-F6812576AEFD"),
        MaestroButton:new(22, deck, hsIcon("pptx/colors/bmp-96/text-green.png.bmp"), "3634BCDF-9426-47ED-94DB-5A2B6AE29C66"),

        MaestroButton:new(7, deck, hsIcon("pptx/colors/bmp-96/fill-red.png.bmp"), "7E4D159E-F181-4D32-B567-033AD826CD6A"),
        MaestroButton:new(15, deck, hsIcon("pptx/colors/bmp-96/line-red.png.bmp"), "39368956-2C5B-41B6-8ACE-AC26D8BE2BFC"),
        MaestroButton:new(23, deck, hsIcon("pptx/colors/bmp-96/text-red.png.bmp"), "6D19B684-4DA2-4566-8F76-FCAACB39FED9"),

        MaestroButton:new(8, deck, hsIcon("pptx/colors/bmp-96/fill-inky-blue.png.bmp"), "796DFBC5-8B80-4422-9AA5-D19DE2A055D4"),
        MaestroButton:new(16, deck, hsIcon("pptx/colors/bmp-96/line-inky-blue.png.bmp"), "6769734A-DC6E-4D4E-9E20-641AD9197005"),
        MaestroButton:new(24, deck, hsIcon("pptx/colors/bmp-96/text-inky-blue.png.bmp"), "7F18E471-F989-4DA0-967D-1E935E3E0FC3"),

        -- TODO verify the action for these two:
        MaestroButton:new(27, deck, hsIcon("pptx/recording/bmp-96/record-pptx.png.bmp"), "B0F6834D-5E1D-4E08-AD92-3C2F87886CC0"),
        MaestroButton:new(28, deck, hsIcon("pptx/recording/bmp-96/record-mouse-only.png.bmp"), "C998899A-74A5-4329-8B94-6E1DE875F32B"),

        MaestroButton:new(30, deck, hsIconWithText("pptx/grouping/bmp-96/group-objects.png.bmp", "\nG", deck, MediumText), "D31AB7EB-3AFC-423E-8029-10C2AB5D5E33"),
        MaestroButton:new(31, deck, hsIconWithText("pptx/grouping/bmp-96/ungroup-objects.png.bmp", "\n\n    UN", deck, MediumText), "5E6CF183-E907-4316-B833-04421A29A304"),
        MaestroButton:new(32, deck, hsIconWithText("pptx/grouping/bmp-96/regroup-objects.png.bmp", "\nRE", deck, MediumText), "21C045E3-ACC3-4EE7-BE19-0EA2D4E68322"),

        LuaButton:new(25, deck, pageLeftImage(deck), changePage(DECK_2XL, APPS.MicrosoftPowerPoint, PAGE_2, PptxObserver)),
    }
end)


PptxObserver:addProfilePage(DECK_3XL, PAGE_1, function(_, deck)
    return {
        -- TODO verify button names are appropriate (the ones claude moved, I did pptx/shapes)
        -- * row 1 (buttons 1-8)
        LuaButton:new(1, deck, hsIcon("pptx/shapes/bmp-96/align-left.png.bmp"), menu({ "Arrange", "Align or Distribute", "Align Left" })),
        LuaButton:new(2, deck, hsIcon("pptx/shapes/bmp-96/align-center.png.bmp"), menu({ "Arrange", "Align or Distribute", "Align Center" })),
        LuaButton:new(3, deck, hsIcon("pptx/shapes/bmp-96/align-right.png.bmp"), menu({ "Arrange", "Align or Distribute", "Align Right" })),
        MaestroButton:new(4, deck, hsIconWithText("pptx/arrange/bmp-96/alignment-objects.png.bmp", "\nAlign Objects", deck, SmallText), "14B23130-38EC-4510-BFE9-557900E13DF6"),
        LuaButton:new(5, deck, hsIcon("pptx/shapes/bmp-96/distribute-vertical.png.bmp"), menu({ "Arrange", "Align or Distribute", "Distribute Vertically" })),
        LuaButton:new(6, deck, hsIcon("pptx/shapes/bmp-96/distribute-horizontal.png.bmp"), menu({ "Arrange", "Align or Distribute", "Distribute Horizontally" })),
        LuaButton:new(8, deck, hsIcon("pptx/shapes/bmp-96/align-top.png.bmp"), menu({ "Arrange", "Align or Distribute", "Align Top" })),

        -- * row 2 (buttons 9-16)
        KeyStrokeButton:new(9, deck, hsIcon("pptx/arrange/bmp-96/hotkey-group-60x60.png.bmp"), { "cmd", "shift" }, ","),
        KeyStrokeButton:new(10, deck, hsIcon("pptx/arrange/bmp-96/hotkey-ungroup-60x60.png.bmp"), { "cmd", "shift" }, "/"),
        MaestroButton:new(11, deck, hsIcon("pptx/picture/bmp-96/resize-plus-one-percent.png.bmp"), "FC2D2B91-F5C3-4C83-9A5D-CEB00CE09D8F"),
        MaestroButton:new(12, deck, hsIcon("pptx/picture/bmp-96/resize-minus-one-percent.png.bmp"), "485063B6-14C6-400F-9BA0-130628467342"),
        MaestroButton:new(13, deck, hsIcon("pptx/transitions/bmp-96/transitions-morph-objects.png.bmp"), "A6B90E50-C53C-44F4-98C4-F8E5059074CA"),
        MaestroButton:new(14, deck, hsIcon("pptx/picture/bmp-96/change-picture-maintain-size.png.bmp"), "7FE31128-978B-4693-B531-B6BDA2C053DE"),
        MaestroButton:new(15, deck, hsIcon("pptx/picture/bmp-96/change-picture-to-20-percent.png.bmp"), "4EF6A3FB-CC2F-4CA2-A936-BDDF7D90F626"),
        LuaButton:new(16, deck, hsIcon("pptx/shapes/bmp-96/align-middle.png.bmp"), menu({ "Arrange", "Align or Distribute", "Align Middle" })),

        -- * row 3 (buttons 17-24)
        LuaButton:new(17, deck, hsIcon("pptx/shapes/bmp-96/flip-vertical.png.bmp"), menu({ "Arrange", "Rotate or Flip", "Flip Vertical" })),
        LuaButton:new(18, deck, hsIcon("pptx/shapes/bmp-96/flip-horizontal.png.bmp"), menu({ "Arrange", "Rotate or Flip", "Flip Horizontal" })),
        LuaButton:new(19, deck, hsIcon("pptx/shapes/bmp-96/rotate-left-90.png.bmp"), menu({ "Arrange", "Rotate or Flip", "Rotate Left 90°" })),
        LuaButton:new(20, deck, hsIcon("pptx/shapes/bmp-96/rotate-right-90.png.bmp"), menu({ "Arrange", "Rotate or Flip", "Rotate Right 90°" })),
        MaestroButton:new(21, deck, hsIcon("pptx/format/bmp-96/format-shape-fill-line.png.bmp"), "63CCD7EB-BB4B-4555-BAF1-D3C0D6034450"),
        MaestroButton:new(22, deck, hsIcon("pptx/format/bmp-96/format-shape-size-rotation.png.bmp"), "0B2D06E8-F001-425E-BB7E-646DB84342D8"),
        MaestroButton:new(23, deck, hsIcon("pptx/format/bmp-96/format-picture-crop.png.bmp"), "A2CAB0BB-5B91-4040-9C5C-E9355F26FA2B"),
        LuaButton:new(24, deck, hsIcon("pptx/shapes/bmp-96/align-bottom.png.bmp"), menu({ "Arrange", "Align or Distribute", "Align Bottom" })),

        -- * row 4 (buttons 25-32)
        KeyStrokeButton:new(25, deck, hsIconWithSmallBlackText("pptx/arrange/bmp-96/bring-to-front-60x60.png.bmp", "\nFront", deck), { "cmd", "shift" }, "f"),
        KeyStrokeButton:new(26, deck, hsIcon("pptx/arrange/bmp-96/send-forward-60x60.png.bmp"), { "cmd", "alt", "shift" }, "f"),
        KeyStrokeButton:new(27, deck, hsIcon("pptx/arrange/bmp-96/send-backward-60x60.png.bmp"), { "cmd", "alt", "shift" }, "b"),
        KeyStrokeButton:new(28, deck, hsIcon("pptx/arrange/bmp-96/send-to-back-60x60.png.bmp"), { "cmd", "shift" }, "b"),
        MaestroButton:new(29, deck, hsIcon("pptx/format/bmp-96/copy-format.png.bmp"), "219BB69A-9C8A-4378-BACE-5AD6B84331DF"),
        MaestroButton:new(30, deck, hsIcon("pptx/animation/bmp-96/animation-painter.png.bmp"), "082B06B7-0846-4981-98F5-0920C4C93CDA"),
        MaestroButton:new(31, deck, hsIcon("pptx/animation/bmp-96/toggle-animation-pane.png.bmp"), "5F3CF10D-FA52-4DD0-AF84-6A0CF443ECF3"),
        MaestroButton:new(32, deck, hsIcon("pptx/animation/bmp-96/toggle-selection-pane.png.bmp"), "E1ED7FC7-FF68-44CC-82F2-4725B34B9E8D"),
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
