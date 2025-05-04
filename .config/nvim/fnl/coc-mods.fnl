;
; FYI if I want to keep any of this, I need to have it be dependent on toggles for which LSP client I am using (coc/cmp/nvim0.11)
;  as well as the LSP

;vim.fn["CocActionAsync"]("documentSymbols", function(err, result)
(local helpers (require "devtools.messasges"))
(vim.keymap.set :n :<leader>xs
                (fn []
                  (vim.fn.CocActionAsync :documentSymbols
                                         (fn cb_ [err_ result]
                                           ;(vim.print result)))))
                                           (helpers.append result)))))

(vim.keymap.set :n :<leader>xd
                (fn []
                  (helpers.append (vim.fn.CocAction :commands))))

(vim.keymap.set :n :<leader>xi
                (fn []
                  (vim.fn.CocActionAsync :documentSymbols
                                         (fn cb_ [err_ result]
                                          (vim.print result)))))
                                           ; (each [_ v (pairs result)]
                                           ;   ;(case ["foo " "bar" "bam"]
                                           ;   (case [v.detail]
                                           ;     nil :ignore-this
                                           ;     [a & b] (and
                                           ;            (vim.print "table!")
                                           ;            ; (vim.print a)
                                           ;            ; (vim.print b)
                                           ;            )
                                           ;     _a :ignore-this-too))))))
                                           ;     ;a (vim.print a)))))))
