;vim.fn["CocActionAsync"]("documentSymbols", function(err, result)
(vim.keymap.set :n :<leader>xs
                (fn []
                  (vim.fn.CocActionAsync :documentSymbols
                                         (fn cb_ [err_ result]
                                           ;(vim.print result)))))
                                           (_G.BufferDump result)))))

(vim.keymap.set :n :<leader>xd
                (fn []
                  (_G.BufferDump (vim.fn.CocAction :commands))))

(vim.keymap.set :n :<leader>xi
                (fn []
                  (vim.fn.CocActionAsync :documentSymbols
                                         (fn cb_ [err_ result]
                                           ;(vim.print result)))))
                                           (each [_ v (pairs result)]
                                             (case v.detail
                                               nil :ignore-this
                                               a (vim.print a)))))))
