-- FYI this is for the config app (button designer)
-- *** NOT part of the streamdeck dir where I was trying to create my own streamdeck control software (didn't finish that)

function SDECKCFG_open_button_color_picker()
    local app = get_app_element_or_throw("com.elgato.StreamDeck")

    -- AXIdentifier: ESDStreamDeckApplication.MainWindow.centralWidget.leftFrame.mainStack.CanvasView.ESDCanvasSplitter.ESDPropertyInspector.PropertyInspectorBase.textEditButton<string>
    -- unique ref: app:window_by_title('Stream Deck'):group(''):splitGroup('')

    local split_group = app:window_by_title("Stream Deck")
        :group_by_description("")
        :splitGroup_by_description("")
    error_if_nil(split_group, "no split group found")

    local button = vim.iter(split_group:buttons())
        :find(function(child)
            return child:axIdentifier():find("textEditButton")
        end)
    error_if_nil(button, "no button found")

    button:performAction("AXPress")

    wait_for_element_then_press_it(function()
        -- FYI will become front window when ready
        -- AXMain: false<bool>
        -- AXRoleDescription: dialog<string>
        -- AXSections: [1: SectionDescription: Content, SectionObject: hs.axuielement: AXCheckBox (0x600002836bb8), SectionUniqueID: AXContent]
        -- AXSubrole: AXDialog<string>
        local front_window = app:window(1)
        error_if_nil(front_window, "no front window found")

        return front_window:button_with_identifier("ESDStreamDeckApplication.ESDPopoverView.ESDTitleStyleEditor.colorButton")
    end)
end
