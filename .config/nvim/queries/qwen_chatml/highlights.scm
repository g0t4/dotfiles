[
  (fim_prefix_token) @qwen_fim_prefix_token
  prefix: (text) @qwen_fim_prefix_contents
]

[
  (fim_suffix_token) @qwen_fim_suffix_token
  suffix: (text) @qwen_fim_suffix_contents
]

[
  (fim_middle_token) @qwen_fim_middle_token
  middle: (text) @qwen_fim_middle_contents
]

[
  (repo_name_token) @qwen_repo_name_token
  repo_name: (until_end_of_line) @qwen_repo_name
]

[
  ; (repo_file) @qwen_repo_file
  (file_sep_token) @qwen_file_sep_token
  path: (until_end_of_line) @qwen_file_path
  contents: (text) @qwen_file_contents
]
