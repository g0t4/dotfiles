function StreamDeckHammerspoonShowConsoleThenReload()
    hs.openConsole()
    hs.console.clearConsole()
    hs.reload()
    -- FYI! once reload() is called, this function is terminated
    --  NOTHING can come after this... it'll basically be ignored
end
