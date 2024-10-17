return {


    -- WAIT WAIT... I should research what nvim has for session management before adding extensions, maybe I don't need any?
    --    or another might work fine ... 
    --    separataly, this extension nails it =>  when start nvim w/o any args then try to find CWD's session and load it (https://neovimcraft.com/plugin/rmagatti/auto-session/)
    --
    -- -- what I want out of a workspace/session:
    -- --   save open files (at least last opened)
    -- --      save/restore window layout (so I can resume where I left off - think :qa and then resume)
    -- --   restore position in buffer (already done via early.lua IIRC)
    -- --   auto save/restore on at least quit/start
    -- --   basically keep some settings within a given project (CWD)
    -- --
    -- --
    -- {
    --     "tpope/vim-obsession",
    --     init = function()
    --         -- better perf if disable writing on BufEnter event:
    --         vim.g.obsession_no_bufenter = 1
    --         -- vim.cmd [[
    --         --     " save session on exit
    --         --     autocmd VimLeavePre * :Obsession!
    --         --     " restore session on start
    --         --     autocmd VimEnter * :Obsession
    --         -- ]]
    --     end
    -- }
    -- -- TODO always have session recording to current dir or? ok I see once you load from a session file, it resumes saving to it... makes sense
    -- --  so, `nvim -S Session.vim` => what about on startup, look for Session.vim and auto restore it?
    -- --     that way once i start a session it is always maintained until I toggle it off w/ `:Obsession!`? 
    -- --
    -- -- FYI part of reason I looked for alternatives was I believe that options are saved and that messed up plugins I was adding... can always go back to basics if I can address that

}
