-- TODO port to ~/.config/tree-sitter/config.json (verbatim can use same RGB values for color + bold/underline work too)!
vim.api.nvim_set_hl(0, "@qwen_fim_prefix_token", { fg = "#6986ff" })
vim.api.nvim_set_hl(0, "@qwen_fim_prefix_contents", { fg = "#6986ff" })
vim.api.nvim_set_hl(0, "@qwen_fim_suffix_token", { fg = "#4ade80" })
vim.api.nvim_set_hl(0, "@qwen_fim_suffix_contents", { fg = "#4ade80" })

vim.api.nvim_set_hl(0, "@qwen_fim_middle_token", { fg = "#ff7eb3" })
vim.api.nvim_set_hl(0, "@qwen_fim_middle_contents", { fg = "#ff7eb3" })

vim.api.nvim_set_hl(0, "@qwen_repo_name_token", { fg = "#ffe66d" })
vim.api.nvim_set_hl(0, "@qwen_repo_name", { fg = "#ffe66d", bold = true })

vim.api.nvim_set_hl(0, "@qwen_file_sep_token", { fg = "#89dceb" })
vim.api.nvim_set_hl(0, "@qwen_file_path", { fg = "#89dceb", bold = true, underline = true })
vim.api.nvim_set_hl(0, "@qwen_file_contents", { fg = "#89dceb" })

-- message types
vim.api.nvim_set_hl(0, "@qwen_system_message", { fg = "#ff6b6b", bold = true, })
vim.api.nvim_set_hl(0, "@qwen_developer_message", { fg = "#f7b267", bold = true, })
vim.api.nvim_set_hl(0, "@qwen_user_message", { fg = "#61afef", })
vim.api.nvim_set_hl(0, "@qwen_assistant_message", { fg = "#98c379", })
vim.api.nvim_set_hl(0, "@qwen_tool_response_message", { fg = "#c678dd", })
vim.api.nvim_set_hl(0, "@qwen_all_other_roles_message", { fg = "#7f848e", italic = true, })
