-- before plugin loader
require("early")

require("bootstrap-lazy")

-- after plugin loader (but not guaranteed to be after specific plugins)
require('non-plugins.werkspaces.werkspace')

vim.cmd [[
    " without this, the cursor line in NvimTree is blindingly bright... and for some reason once it is used it sets CursorLine in subsequently opened files... very strange
    "   this forces NvimTreeCursorLine to be the same as CursorLine
    " NvimTreeCursorLine xxx guibg=#5c6370
    " CursorLine     xxx guibg=#2d313b
    highlight! link NvimTreeCursorLine CursorLine
]]
