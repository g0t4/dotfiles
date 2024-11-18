
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
        -- config = function()
        --     require("dap").setup()
        -- end,
    },

    -- {
    --     "puremourning/vimspector",
    --     config = function()
    --         require("vimspector").setup()
    --     end,
    -- },

    -- {
    --     "mfussenegger/nvim-dap-python",
    --     config = function()
    --         require("dap-python").setup("python")
    --     end,
    -- }

}
