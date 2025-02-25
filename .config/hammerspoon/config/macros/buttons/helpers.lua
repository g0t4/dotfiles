function resetButton(buttonNumber, deck)
    -- wipes color/image
    -- seems like a reset :)
    -- TODO is this at all a problem?
    deck:setButtonColor(buttonNumber, hs.drawing.color.x11.black)
end
