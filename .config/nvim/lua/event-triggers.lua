local M = {} -- module table (exports)

-- plugins that aren't needed until a file is opened (BufRead), OR when a new file is created which InsertEnter is a surrogate for
M.buffer_with_content_events = { "BufRead", "InsertEnter" } -- TODO any edge cases where a buffer would have something loaded and not trip BufRead/InsertEnter?
-- FYI it is possible that lazy loading these plugins is pointless... aside from some minor edge case timing of nvim startup, cuz most of the time you are editing a buffer, so drop these if they become a problem

return M
