-- FYI this is for the config app (button designer)
-- *** NOT part of the streamdeck dir where I was trying to create my own streamdeck control software (didn't finish that)

function SDECKCFG_open_button_color_picker()
    local app = get_app_element_or_throw("com.elgato.StreamDeck")

    -- app:window(1):group(1):splitGroup(1):button(4)
    --
    -- AXEnabled: true<bool>
    -- AXFocused: false<bool>
    -- AXIdentifier: ESDStreamDeckApplication.MainWindow.centralWidget.leftFrame.mainStack.CanvasView.ESDCanvasSplitter.ESDPropertyInspector.PropertyInspectorBase.textEditButton<string>
    -- AXIndex: 0<number>
    -- AXRoleDescription: button<string>
    -- frame: x=773.0,y=718.0,w=26.0,h=18.0
    --
    -- press 'c' children, 'e' everything
    --
    -- unique ref: app:window_by_title('Stream Deck'):group(''):splitGroup('')

    local split_group = app:window_by_title("Stream Deck")
        :group_by_description("")
        :splitGroup_by_description("")

    -- search the Identifier
    local button = vim.iter(split_group:buttons())
        :find(function(child)
            return child:axIdentifier():find("textEditButton")
        end)
    if not button then
        error("no button found")
    end
    button:performAction("press")
end
