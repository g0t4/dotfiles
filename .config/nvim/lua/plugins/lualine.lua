return {
    {
        "nvim-lualine/lualine.nvim",

        dependencies = { 'nvim-tree/nvim-web-devicons' },
        -- TODO consider "kyazdani42/nvim-web-devicons" (lua rewrite) if some reaosn to do so, i.e. perf? or other forks?
        config = function()
            -- credit / from https://neovimcraft.com/plugin/SmiteshP/nvim-navic/

            local function statusline_filetype()
                --  lua
                --  why show the icon too? given the icon alone isn't as telling as the filetype, then just show the darn filetype
                --  AND why show filetype if the filename has the same extension as it!?

                local file_ext = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':e')

                if file_ext == vim.bo.filetype then
                    return ""
                end
                return vim.bo.filetype
            end

            local function statusline_nvim_tree()
                return " " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t") -- only show last part of path (folder name)
            end

            local function statusline_copilots_status()
                -- need this wrapper b/c if I put a user defined function in the statusline and it doesn't exist it is permanently disabled basically, so this won't blow up and will dynamically figure out which status to show too
                local status = ""
                if vim.fn.exists("*GetStatusLineCopilot") == 1 then
                    status = vim.fn["GetStatusLineCopilot"]()
                end
                -- PRN if I add mechanism to switch copilot/supermaven w/o restart nvim then I can check more than just if func exists
                if type(_G["GetStatusLineSupermaven"]) == "function" then
                    status = status .. " " .. _G["GetStatusLineSupermaven"]()
                end
                return status
            end

            local function workspace_name()
                -- wait to show more (above) the CWD, but I suspect I might want to see a github org/repo name... not sure... could I check what other instances of nvim are running and if two have diff CWDs but same last component then show dir above? i.e. open upstream + fork at same time (again, wait to be confused before adding any of this)
                return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
            end

            require("lualine").setup {
                -- default: https://github.com/nvim-lualine/lualine.nvim#default-configuration
                options = {
                    -- section_separators = { left = vim.fn.nr2char(0xE0B4), right = vim.fn.nr2char(0xE0B6) },
                    -- section_separators = { left = "", right = "" },
                    -- section_separators = { left = "▌", right = "▐" },
                    section_separators = "",
                    component_separators = "",
                    -- globalstatus  -- only one status line? hrm... might work now that I have inactive windows dimmed in onedarkpro theme
                    --
                    theme = require("localz.lualine-theme").theme(),

                },
                -- FYI =>    :lua print(vim.inspect(require('lualine').get_config()))
                -- extensions = { 'nvim-tree' }, -- shows root dir (and dirs above it) in statusline... I dont need that, in fact if anything show file path of the file still that was right before open treeview
                -- FYI do not use a function that may not exist before this is loaded else the component will be gone the entire nvim session (see what I did with copilot statusline)
                sections = {
                    -- commandline shows mode already so why put it here too? plus lualine has color changes
                    -- lualine_a = { 'buffers' }, -- TODO "buffers" looks interesting! shows tabs for each file... might be what I've been wanting?
                    --    also has tabs/windows... interesting (is that for tab strip,  or?)
                    lualine_a = { '' },
                    lualine_b = { { -- FYI wrap in {} to customize component options
                        --   https://github.com/nvim-lualine/lualine.nvim#filename-component-options
                        "filename",
                        path = 1, -- 1 = relative path, 4 = filename+parentdir sounds interesting
                        -- relative path, 4 filename+parentdir sounds interesting
                    } }, -- filename includes modified
                    -- lualine_c = { "filetype" },
                    lualine_c = { statusline_filetype, statusline_copilots_status },
                    lualine_x = {}, -- todo move copilot back here?
                    lualine_y = {
                        {
                            function()
                                return vim.fn.line(".") .. ""
                            end,
                        },
                        {
                            function()
                                return vim.fn.col(".") .. ""
                            end,
                            padding = { left = 0, right = 1 }
                        }, -- FYI when set padding it overrides both sides, so only specify left means right = 0
                        { "progress", padding = { right = 1 } },
                    },
                    lualine_z = {
                        {
                            workspace_name,
                        }
                    },
                    -- search shows #/total in commandline so don't need that here
                },
                inactive_sections = {
                    lualine_a = {}, -- default ""
                    lualine_b = { "filename" }, -- default ""
                    lualine_c = { "" }, -- default "filename"
                    lualine_x = { "location" }, -- default "location"
                    lualine_y = {}, -- default ""
                    lualine_z = {}, -- default ""
                },
                -- extensions = { 'nvim-tree' },
                extensions = {
                    {
                        filetypes = {
                            "NvimTree",
                        },
                        sections = {
                            lualine_a = { statusline_nvim_tree },
                        },
                    }
                }
            }
        end,
        -- Notes:
        -- - onedarkpro supports lualine OOB
    },
}
