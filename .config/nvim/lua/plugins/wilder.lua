return {



    {
        "gelguy/wilder.nvim",
        config = function()
            -- TODO port config from vimrc
            require("wilder").setup {
                modes = {
                    "/",
                    "?",
                    ":",
                    ";",
                },
            }
        end,

    }

}
