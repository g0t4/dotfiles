local use_dap = false
if not use_dap then
    return {}
end

function setup_python_dap()
    -- local dap = require('dap')
    -- dap.adapters.python = function(cb, config)
    --     if config.request == 'attach' then
    --         ---@diagnostic disable-next-line: undefined-field
    --         local port = (config.connect or config).port
    --         ---@diagnostic disable-next-line: undefined-field
    --         local host = (config.connect or config).host or '127.0.0.1'
    --         cb({
    --             type = 'server',
    --             port = assert(port, '`connect.port` is required for a python `attach` configuration'),
    --             host = host,
    --             options = {
    --                 source_filetype = 'python',
    --             },
    --         })
    --     else
    --         cb({
    --             type = 'executable',
    --             command = 'path/to/virtualenvs/debugpy/bin/python',
    --             args = { '-m', 'debugpy.adapter' },
    --             options = {
    --                 source_filetype = 'python',
    --             },
    --         })
    --     end
    -- end
end

return {

    -- !!! TODO try either/both vimspector vs nvim-dap
    --   others?
    -- wants:
    --   DAP support
    --   best nvim integration and experience, not necessarily all debugger features ever
    --   I rarely use debuggers so I can compromise and don't need all the features
    -- [vimspector](https://github.com/puremourning/vimspector)
    --   [languages](https://github.com/puremourning/vimspector/wiki/Additional-Language-Support)
    --   pros:
    --   cons:
    -- nvim-dap:
    --   pros:
    --   cons:
    --
    -- differences not as important to me:
    --   nvim-dap is nvim only, vimspector works in vim... not sure which way this is pro or con, right now I am focused on nvim config (would be much work to go back to just vim)

    {
        "mfussenegger/nvim-dap",
        -- https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
        --
        -- keys = {
        -- TODO keys for keymaps (so legendary picks them up)

        config = function()
            -- require("dap").setup()
            -- setup_python_dap()
            -- TODO can I enable these when debugging only and go back to my regualar set when not???
            --    and by that I mean F5,F10, etc not leader keys
            --    ACTUALLY I always have felt the F key hard to remember b/c I rarely debug and cuz there's no logic to the assignments (and they change in some tools)... so maybe I will like leader keys! will spell like the action
            vim.keymap.set('n', '<leader>dc', function() require('dap').continue() end)  -- <F5>?
            vim.keymap.set('n', '<leader>so', function() require('dap').step_over() end) -- F10?
            vim.keymap.set('n', '<leader>si', function() require('dap').step_into() end) -- F11?
            vim.keymap.set('n', '<leader>su', function() require('dap').step_out() end)  -- F12? (s[u] == step up?)
            vim.keymap.set('n', '<leader>sb', function() require('dap').step_back() end)
            -- .pause()
            -- .reverse_continue()
            -- .up()
            -- .down()
            -- .restart_frame()
            -- .run_to_cursor() ***
            -- .set_log_level() ***
            -- .disconnect()
            -- .session/sessions() / .status() / .close()
            -- .launch()
            -- .attach()
            vim.keymap.set('n', '<Leader>b', function() require('dap').toggle_breakpoint() end)
            vim.keymap.set('n', '<Leader>B', function() require('dap').set_breakpoint() end)
            vim.keymap.set('n', '<Leader>dl', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
            vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.toggle() end) -- toggle instead of open/close
            -- I will likely use legendary for remembering these commands and so its fine for a few to be unrealistic to type out and just for lookup only:
            vim.keymap.set('n', '<Leader>d_r', function()
                require('dap').repl.open()
                require('dap.ext.debugger').restart()
            end)
            vim.keymap.set('n', '<Leader>dt', function()
                require('dap').repl.open()
                require('dap.ext.debugger').terminate()
            end)
            vim.keymap.set('n', '<Leader>d_run_last', function() require('dap').run_last() end) -- a as in again?
            vim.keymap.set({ 'n', 'v' }, '<Leader>dh', function() require('dap.ui.widgets').hover() end)
            vim.keymap.set({ 'n', 'v' }, '<Leader>dp', function() require('dap.ui.widgets').preview() end)
            vim.keymap.set('n', '<Leader>df', function()
                local widgets = require('dap.ui.widgets')
                widgets.centered_float(widgets.frames)
            end)
            vim.keymap.set('n', '<Leader>ds', function()
                local widgets = require('dap.ui.widgets')
                widgets.centered_float(widgets.scopes)
            end)
            -- TODO other keymaps?
        end,
        -- config = function()
        --     require("dap").setup()
        -- end,
        -- notes:
        --   launch.json support!
        --   completions omnifunc from debugger
        --   REPL
        -- TODO try:
        --   SIGNS:
        --      vim.fn.sign_define('DapBreakpoint', {text='🛑', texthl='', linehl='', numhl=''})
        --
        --   REPL completions?
        --     au FileType dap-repl lua require('dap.ext.autocompl').attach()
        --   why does repl (like terminal) not show the cursor after the prompt on first open?
        --   Esc should close float windows? is it possible to show hover and when move cursor off symbol it closes?
        --   Keep breakpoints between restarts of nvim?
    },

    -- {
    --     "puremourning/vimspector",
    --     config = function()
    --         require("vimspector").setup()
    --     end,
    -- },

    {
        "mfussenegger/nvim-dap-python",
        config = function()
            require("dap-python").setup("python")
        end,
    }

}
