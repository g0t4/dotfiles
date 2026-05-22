function PPTX_EnsureTabOpen(tabName)
    MicrosoftOfficeEnsureTabSelected("Microsoft PowerPoint", tabName)
end

---@return hs.axuielement
function GetPowerPointAppElement()
    return GetAppElement("PowerPoint")
    -- return GetAppElement("com.microsoft.PowerPoint")
end

function PPTX_SaveAs()
    local app = GetPowerPointAppElement()

    PressMenuItem({ "File", "Export..." })

    -- * sheet attrs:
    -- AXDescription: export<string>
    -- AXIdentifier: save-panel<string>
    -- AXRoleDescription: sheet<string>

    -- * name textbox control:
    --  app:window(1):sheet(1):splitGroup(1):textField(2)
    -- AXIdentifier: saveAsNameTextField<string>
    -- AXFocused: true<bool> -- PRN wait for this to be true if not focused fast enough for above wait_for_element
    -- unique ref: app:window('thumbs'):sheet():splitGroup()   --
    --
    local save_as_name = wait_for_element(function()
        return app:window(1):sheet(1):splitGroup(1):textField(2)
    end, 100, 200) -- 200 cycles × 100 ms/cycle = 20 000 ms → 20 seconds (for restart to complete and find and reopen project)
    -- set name to just "thumb" instead of thumbs
    save_as_name:setAttributeValue("AXValue", "thumb.png")

    -- * file format control:
    -- app:window(1):sheet(1):splitGroup(1):group(2):popUpButton(1)
    -- AXDescription: File Format:<string>
    -- AXValue: PDF<string>
    -- unique ref: app:window('thumbs'):sheet():splitGroup():group(subrole='AXHostingView'):popUpButton()
    local file_format = app:window(1):sheet(1):splitGroup(1):group(2):popUpButton(1)
    -- set AXValue does not work to change selection in dropdown
    file_format:axPress()
    -- PRN you could use wait_for_element_then_press_it

    -- FYI you can also type PNG to select it
    local png_menu_item = file_format:menu(1):menuItem_by_title("PNG")
    png_menu_item:axPress()
    --
    -- * PNG menu item control:
    -- app:window(1):sheet(1):splitGroup(1):group(2):popUpButton(1):menu(1):menuItem(6)
    -- AXIdentifier: menuAction:<string>
    -- AXMenuItemCmdModifiers: 8<number>
    -- AXMenuItemPrimaryUIElement: AXMenuItem 'PNG' menuAction:<hs.axuielement>
    -- AXTitle: PNG<string>
    -- unique ref: app:window('thumbs'):sheet():splitGroup():group(subrole='AXHostingView'):popUpButton():menu()
    --   :menuItem('PNG')


    -- PRN set other options that seem to default to last value or the value I want:
    -- * checkbox => save only current slide
    -- app:window(1):sheet(1):splitGroup(1):group(2):radioGroup(1):radioButton(2)
    -- AXRoleDescription: radio button<string>
    -- AXSelected: true<bool>
    -- AXValue: 1<number>
    -- unique ref: app:window('thumbs'):sheet():splitGroup():group(subrole='AXHostingView'):radioGroup()
    --   :radioButton(desc='Save Current Slide Only')

    -- * width/height => 1920/1080 controls
end
