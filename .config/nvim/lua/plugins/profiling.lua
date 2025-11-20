return {
    {
        -- profiling lua in nvim
        -- https://github.com/t-troebst/perfanno.nvim
        "t-troebst/perfanno.nvim",
        enabled = false, -- FYI only enable when you need to do testing
        cmd = { "PerfLuaProfileStart", "PerfAnnotate", },
        config = function()
            require("perfanno").setup {
                formats = {
                    { percent = true,  format = "%.2f%%", minimum = 0.00000 },
                    { percent = false, format = "%d",     minimum = 0 }
                }
            }
        end
    }
}
