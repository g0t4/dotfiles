source (status dirname)/github.fish

@test "copy_github_link" (copy_github_link /Users/wesdemos/repos/github/g0t4/ask-openai.nvim/lua/ask-openai) = 'https://github.com/g0t4/ask-openai.nvim/tree/master/lua/ask-openai/'
#
# raw is not a think for directories (AFAICT):
# @test "copy_github_raw_link" (copy_github_raw_link /Users/wesdemos/repos/github/g0t4/ask-openai.nvim/lua/ask-openai) = 'https://raw.githubusercontent.com/g0t4/ask-openai.nvim/refs/heads/master/lua/ask-openai'

@test "copy_github_link" (copy_github_link /Users/wesdemos/repos/github/g0t4/ask-openai.nvim/lua/ask-openai/api.lua) = 'https://github.com/g0t4/ask-openai.nvim/blob/master/lua/ask-openai/api.lua'
@test "copy_github_raw_link" (copy_github_raw_link /Users/wesdemos/repos/github/g0t4/ask-openai.nvim/lua/ask-openai/api.lua) = 'https://raw.githubusercontent.com/g0t4/ask-openai.nvim/refs/heads/master/lua/ask-openai/api.lua'
