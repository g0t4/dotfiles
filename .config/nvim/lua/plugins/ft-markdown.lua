return {
    -- FYI spec: https://lazy.folke.io/spec

    -- TODO try this one: https://dotfyle.com/plugins/OXY2DEV/markview.nvim
    --    difference is it renders a preview in normal mode and when in insert mode only shows raw markdown of current block/element IIUC, interesting idea... it's not a preview so much as a better way to edit

    {
        -- discussion about if unmaintained... works though so YMMV: https://github.com/iamcco/markdown-preview.nvim/issues/688
        -- not necessary to `npx yarn build`... `npm install` worked fine for me in the app dir as is show here:

        "iamcco/markdown-preview.nvim",
        enabled = false, -- causing issues during update (rebuild fails w/ npm/yarn error, figure out later or just use a diff plugin)

        ft = { "markdown" }, -- lazy load for markdown files only

        -- if any issues w/ not opening preview (browser), re-install (comment out, lazy clean, uncomment back, lazy install)
        -- FYI when app install works => s/b app/node_modules
        build = "cd app && npm install", -- build is equivalent to run (packer, IIUC)

        init = function()
            -- feels duplicative but this is extension specific setting
            vim.g.mkdp_filetypes = { "markdown" }
        end,
    },

    -- -- another good markdown extension with only difference being that it opens a webview window (if configured to do so) instead of a browser window, so I don't need it too
    -- -- uses deno which is another dep I don't care to have everywhere, unless this were a better ext
    -- -- IIRC this one appears maintained (at least vs iamcco above)
    -- {
    --     "toppair/peek.nvim",
    --     ft = { "markdown" }, -- lazy load for markdown files only
    --     -- event = "VeryLazy", -- this is in peek's docs but I changed to ft (above), why load until open a md file?
    --     build = "deno task --quiet build:fast",
    --     config = function()
    --         require("peek").setup({
    --             app = "webview", -- or "browser"
    --         })
    --         -- perfectly fine to leave these here, don't show them until needed?
    --         vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
    --         vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
    --     end,
    --     -- install deno on system
    -- }

    -- NOTES:
    -- markdown rendering:
    -- https://github.com/MeanderingProgrammer/render-markdown.nvim
    --
    -- previewer: look promising https://github.com/jannis-baum/vivify.vim
    --

}
