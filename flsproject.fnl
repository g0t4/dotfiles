; https://git.sr.ht/~xerool/fennel-ls/tree/HEAD/docs/manual.md#configuration
;   see this page about downloading docsets and config below...
;   i.e. ~/.local/share/fennel-ls/docsets/nvim.lua
;   YUP it was too old from luarocks, use the repo to install it (build / user install):
;     https://git.sr.ht/~xerool/fennel-ls/tree/main/docs/installation.md
;   btw repo keys:
;     https://man.sr.ht/git.sr.ht/#ssh-host-keys:
;
;   https://git.sr.ht/~xerool/fennel-ls/tree/HEAD/docs/manual.md#configuration
;
;   Yes docsets!
;     https://wiki.fennel-lang.org/LanguageServer
;     curl -o $HOME/.local/share/fennel-ls/docsets/nvim.lua https://git.sr.ht/~micampe/fennel-ls-nvim-docs/blob/main/nvim.lua

;
;{:fennel-path "./?.fnl;./?/init.fnl;src/?.fnl;src/?/init.fnl"
; :macro-path "./?.fnl;./?/init-macros.fnl;./?/init.fnl;src/?.fnl;src/?/init-macros.fnl;src/?/init.fnl"
; :lua-version "lua5.4"
; :libraries {}
; :extra-globals ""
; :lints {:unused-definition true
;         :unknown-module-field true
;         :unnecessary-method true
;         :unnecessary-tset true
;         :unnecessary-do true
;         :redundant-do true
;         :match-should-case true
;         :bad-unpack true
;         :var-never-set true
;         :op-with-no-arguments true
;         :multival-in-middle-of-call true
;         :no-decreasing-comparison false}


; FML... nothing is working to use these settings...
;   tried fennel-ls too and no joe, is it not detecting this config file?
;   fennel-ls --lint .config/nvim/fnl/testme.fnl
;   but then strange enough.. in this file I get LS completions for vim.* wtf?!?
{
:libraries {:nvim true}
;:extra-globals "vim"
}

