;vim.fn["CocActionAsync"]("documentSymbols", function(err, result)
(vim.keymap.set :n :<leader>xs
                (fn []
                  (vim.fn.CocActionAsync :documentSymbols
                                         (fn cb_ [err_ result]
                                           ;(vim.print result)))))
                                           (BufferDump result)))))
