-- FYI this is for the config app (button designer)
-- *** NOT part of the streamdeck dir where I was trying to create my own streamdeck control software (didn't finish that)

function SDECKCFG_open_button_color_picker()
    local app = get_app_element_or_throw("com.elgato.StreamDeck")

    -- AXIdentifier: ESDStreamDeckApplication.MainWindow.centralWidget.leftFrame.mainStack.CanvasView.ESDCanvasSplitter.ESDPropertyInspector.PropertyInspectorBase.textEditButton<string>
    -- unique ref: app:window_by_title('Stream Deck'):group(''):splitGroup('')

    local split_group = app:window_by_title("Stream Deck")
        :group_by_description("")
        :splitGroup_by_description("")

    local button = vim.iter(split_group:buttons())
        :find(function(child)
            return child:axIdentifier():find("textEditButton")
        end)
    if not button then
        error("no button found")
    end
    print("found button", button:axIdentifier()) -- "ESDStreamDeckApplication
    button:performAction("AXPress")
end
