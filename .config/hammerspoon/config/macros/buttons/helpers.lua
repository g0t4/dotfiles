function resetButton(buttonNumber, deck)
    -- wipes color/image
    -- seems like a reset :)
    -- TODO is this at all a problem?
    deck:setButtonColor(buttonNumber, hs.drawing.color.x11.black)
end

function getDeckName(deck)
    -- CL start
    --  + 9 end => deck 1XL
    --  + 1 end => deck 2XL
    --  + 8 end => deck 3XL
    -- A start (also ends with 4) => deck 4+

    local serial = deck:serialNumber()
    if serial:find("9$") then
        return "1XL"
    elseif serial:find("1$") then
        return "2XL"
    elseif serial:find("8$") then
        return "3XL"
    elseif serial:find("^A") then
        return "4+"
    end
    return "unknown"
end
