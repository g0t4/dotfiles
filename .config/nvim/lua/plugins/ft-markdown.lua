return {
    -- FYI spec: https://lazy.folke.io/spec

    {
        -- discussion about if unmaintained... works though so YMMV: https://github.com/iamcco/markdown-preview.nvim/issues/688
        -- not necessary to `npx yarn build`... `npm install` worked fine for me in the app dir as is show here:

        "iamcco/markdown-preview.nvim",

        -- lazy load on:
        ft = { "markdown" },
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },

        -- if any issues w/ not opening preview (browser), re-install (comment out, lazy clean, uncomment back, lazy install)
        -- FYI when app install works => s/b app/node_modules
        build = "cd app && npm install", -- build is equivalent to run (packer, IIUC)

        init = function()
            -- feels duplicative but this is extension specific setting
            vim.g.mkdp_filetypes = { "markdown" }
        end,
    },

    {
        "toppair/peek.nvim",
        event = "VeryLazy",
        build = "deno task --quiet build:fast",
        config = function()
            require("peek").setup({
                app = "webview", -- or "browser"
            })
            vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
            vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
        end,
        -- deno based: https://github.com/toppair/peek.nvim?tab=readme-ov-file ... might be good, appears to maybe have builtin window preview?
        -- install deno on system
    }

    -- NOTES:
    -- markdown rendering:
    -- https://github.com/MeanderingProgrammer/render-markdown.nvim
    --
    -- previewer: look promising https://github.com/jannis-baum/vivify.vim
    --

}
