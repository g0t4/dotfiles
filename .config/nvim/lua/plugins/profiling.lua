return {
    {
        -- profiling lua in nvim
        -- https://github.com/t-troebst/perfanno.nvim
        "t-troebst/perfanno.nvim",
        -- enabled = false,
        cmd = { "PerfLuaProfileStart", "PerfAnnotate", },
        config = function()
            require("perfanno").setup()
        end
    }
}
