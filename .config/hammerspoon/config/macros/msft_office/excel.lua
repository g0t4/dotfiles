function StreamDeckExcelEnsureTabOpen(tabName)
    MicrosoftOfficeEnsureTabSelected("Microsoft Excel", tabName)
end

function StreamDeckExcelDataTabClickSortButton()
    -- NOTES for sort button:
    -- app:window(1):tabGroup(1):scrollArea(1):group(4):button(3)
    -- scrollArea(1) is only scroll area

    MicrosoftOfficeClickTabButtonByTitle("Microsoft Excel", "Data", "Sort")
end

function StreamDeckExcelDataTabClickReapplyButton()
    MicrosoftOfficeClickTabButtonByTitle("Microsoft Excel", "Data", "Reapply")
end

function StreamDeckExcelDataTabClickFilterButton()
    MicrosoftOfficeClickTabButtonByTitle("Microsoft Excel", "Data", "Filter")
end

function StreamDeckExcelDataTabClickClearButton()
    MicrosoftOfficeClickTabButtonByTitle("Microsoft Excel", "Data", "Clear")
end

-- !!! FYI CLICK INTO CELL (toedit it) and you can get a ref to it usin my inspector OR UI Element Inspector
--    this was for 3rd column of row 5... COORDINATES IN VISIBLE SHEET CELLS ONLY (not overall)
--    app:window(1) :splitGroup(1):layoutArea(1):layoutArea(1):table(2):row(5):cell(3):group(1):textArea(1)
function StreamDeckExcelTestCellAccess()
    local app = get_app_element_or_throw("Microsoft Excel")
    local currentSheet = app:window(1):splitGroup(1):layoutArea(1):layoutArea(1):table(2)
    -- :row(5):cell(3):group(1):textArea(1)
    local function row(rowNum)
        return currentSheet:row(rowNum)
    end
    local function cell(rowNum, colNum)
        return row(rowNum):cell(colNum)
    end
    local function cellGroup(rowNum, colNum)
        return cell(rowNum, colNum):group(1)
    end
    local function cellTextArea(rowNum, colNum)
        return cellGroup(rowNum, colNum):textArea(1)
    end
    local function cellText(rowNum, colNum)
        return cellTextArea(rowNum, colNum):attributeValue("AXValue") or ""
    end
    -- TODO idea... click that fucking filter tiny ass button on top of column of current selected cell!

    print("cell text: ", cellText(5, 3))
end
