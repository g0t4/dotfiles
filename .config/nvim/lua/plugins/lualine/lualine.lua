local cached = {}


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

local function workspace_name()
    -- PRN compute on startup so this func isn't even called?
    if cached.workspace_name then
        return cached.workspace_name
    end

    -- TODO if in a git repo, show org/repo
    local name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t") -- ~ 20us
    if name == "course-bash" then
        name = "course"
    end
    cached.workspace_name = name
    return name
end

local function tabline_visible()
    local show = vim.o.showtabline -- 2 == always, 1 == only > 1 tab, 0 == never
    local never_show_tabline = show == 0
    if never_show_tabline then
        return false
    end
    local always_show_tabline = show == 2
    if always_show_tabline then
        return true
    end
    -- only visible when 2+ tabs
    local tab_count = #vim.api.nvim_list_tabpages()
    return tab_count > 1
end

local function workspace_name_for_statusline()
    if tabline_visible() then
        -- tabline also has workspace_name, so skip it for status line
        return ""
    end
    return workspace_name()
end


return {
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        -- TODO consider "kyazdani42/nvim-web-devicons" (lua rewrite) if some reaosn to do so, i.e. perf? or other forks?
        config = function()
            require("lualine").setup {
                options = {
                    -- separators waste space!
                    section_separators = "",
                    component_separators = "",
                    theme = require("plugins.lualine.theme").theme(),
                    -- always_show_tabline = false,
                },
                sections = {
                    -- commandline shows mode already so why put it here too? plus lualine has color changes
                    lualine_a = { '' },
                    lualine_b = {
                        -- https://github.com/nvim-lualine/lualine.nvim#filename-component-options
                        { "filename", path = 1 } -- 1 = relative path
                    },
                    lualine_c = { statusline_filetype, unpack(CopilotsStatus()), },
                    lualine_x = {},
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
                        -- { workspace_name_for_statusline },
                    },
                    -- search shows #/total in commandline so don't need that here
                },
                inactive_sections = {
                    lualine_a = {}, -- default ""
                    lualine_b = {
                        { "filename", path = 1 },
                    }, -- default ""
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
                },

                -- winbar = {}, inactive_winbar = {} -- basically can have status line at top of window (too or instead)

                tabline = {
                    lualine_a = {
                        -- https://github.com/nvim-lualine/lualine.nvim#tabs-component-options
                        { "tabs",
                            mode            = 1,
                            use_mode_colors = true,
                            -- component_separators = { left = '', right = '' },
                            -- section_separators   = { left = '', right = '' },
                            path            = 0,
                            symbols         = { modified = '+', },

                            fmt             = function(name, context)
                                -- add icon to left of active filename (per tab)
                                local devicons = require('nvim-web-devicons')
                                local icon, _ = devicons.get_icon(name, nil, { default = true })
                                return icon .. ' ' .. name
                            end,
                            -- allow stretching full width of screen (tabline) => else limited to left half (ish) and scrolls in an ugly way
                            max_length = vim.o.columns - 1,
                        },
                    },
                    -- lualine_b = {},
                    -- lualine_c = {},
                    -- lualine_x = {},
                    -- lualine_y = {
                    --     -- 'lsp_status'
                    -- },
                    lualine_z = {
                        -- { 'searchcount' },
                        { workspace_name }, -- only issue is if I don't want tab bar always visible (i.e. only one open tab)... then I lose this
                    },
                }
            }
        end,
    },

    -- {
    --     "akinsho/bufferline.nvim",
    --     dependencies = {
    --         "nvim-tree/nvim-web-devicons",
    --     },
    --     opts = {
    --         options = {
    --             mode = "tabs", -- show tabs instead of buffers, for now this is my preference
    --             -- TODO try using bufferline in the future, see how I feel about it... I suspect I want tabs
    --             --   BTW, has groups concept to group buffers, but that seems to be back to tabs? would be across tabs though (IIUC)
    --             -- separator_style= "padded_slant" -- too much space wasted but iTerm2 appears to need padded :(
    --         },
    --     },
    -- }

}
