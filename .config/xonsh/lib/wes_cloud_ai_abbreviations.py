"""Cloud Ai abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

import re

from wes_abbreviations import AbbreviationRegistry, abbr
from wes_misc_abbreviation_bridge import (
    fish_abbreviation,
)


FISH_FUNCTIONS = (
    'actw_expanded',  # Fish line 1359
    'rg_cached_models',  # Fish line 1468
    'ols_qwen_debug',  # Fish line 1625
    'ols_qwen',  # Fish line 1631
    'cd2',  # Fish line 1646
    'abbr_agg',  # Fish line 2819
    '_define_devtools_abbrs',  # Fish line 2874
    'commands_log_executable_mode',  # Fish line 2898
    'commands_log_shell_mode',  # Fish line 2902
    'trash_n_tail',  # Fish line 2920
    '_taild',  # Fish line 2927
    'rebuild_llama_cpp',  # Fish line 2936
    'build_llama_cpp',  # Fish line 2964
    'test_vllm_v1_completions_streaming',  # Fish line 3014
    'test_vllm_v1_completions',  # Fish line 3022
    'test_vllm_v1_completions_raw_text',  # Fish line 3029
)


def register_cloud_ai_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, 'actw', fish_abbreviation('actw_expanded'))  # Fish line 1370
    abbr(registry, 'azal', 'az account list --output table')  # Fish line 1451
    abbr(registry, 'azall', 'az account list-locations --output table')  # Fish line 1452
    abbr(registry, 'azrl', 'az resource list --output table')  # Fish line 1455
    abbr(registry, 'azrs', 'az resource show --output table')  # Fish line 1456
    abbr(registry, 'azgl', 'az group list --output table')  # Fish line 1458
    abbr(registry, 'azwl', 'az webapp list --output table')  # Fish line 1461
    abbr(registry, 'azasl', 'az appservice plan list --output table')  # Fish line 1462
    abbr(registry, 'hfc', 'hf cache')  # Fish line 1511
    abbr(registry, 'hfcls', 'hf cache ls --no-truncate --revisions')  # Fish line 1513
    abbr(registry, 'hfcpr', 'hf cache prune')  # Fish line 1518
    abbr(registry, 'hfcrm', 'hf cache rm')  # Fish line 1520
    abbr(registry, 'hfcv', 'hf cache verify')  # Fish line 1521
    abbr(registry, 'hfc_downloadInProgress', 'fd .downloadInProgress ~/.cache/huggingface/')  # Fish line 1522
    abbr(registry, 'hfml', 'hf models ls')  # Fish line 1524
    abbr(registry, 'hfmls', 'hf models ls --search')  # Fish line 1525
    abbr(registry, 'hfmlsa', 'hf models ls --limit 30 --author')  # Fish line 1526
    abbr(registry, 'hfmls_ggml_org', 'hf models ls --limit 30 --author ggml-org')  # Fish line 1527
    abbr(registry, 'hfmls_ggml_org_qwen36', 'hf models ls --limit 30 --author ggml-org --search qwen3.6')  # Fish line 1529
    abbr(registry, 'hfmls_ggml_org_qwen35', 'hf models ls --limit 30 --author ggml-org --search qwen3.5')  # Fish line 1530
    abbr(registry, 'hfmls_qwen', 'hf models ls --limit 30 --author Qwen')  # Fish line 1531
    abbr(registry, 'hfmls_qwen_qwen36', 'hf models ls --limit 30 --author Qwen --search qwen3.6')  # Fish line 1532
    abbr(registry, 'hfmls_qwen_qwen35', 'hf models ls --limit 30 --author Qwen --search qwen3.5')  # Fish line 1533
    abbr(registry, 'hfmi', 'hf models info')  # Fish line 1535
    abbr(registry, 'hfdl', 'hf datasets ls')  # Fish line 1537
    abbr(registry, 'hfdls', 'hf datasets ls --search')  # Fish line 1538
    abbr(registry, 'hfdla', 'hf datasets ls --author')  # Fish line 1539
    abbr(registry, 'hfdinfo', 'hf datasets info')  # Fish line 1540
    abbr(registry, 'hfcols', 'hf collections ls --owner')  # Fish line 1542
    abbr(registry, 'hfcols_ggml_org', 'hf collections ls --owner ggml-org')  # Fish line 1543
    abbr(registry, 'hfcols_qwen', 'hf collections ls --owner Qwen')  # Fish line 1544
    abbr(registry, 'hfcoi', 'hf collections info % | jq ".items | .[] | [ .item_type, .item_id ] " --compact-output')  # Fish line 1545
    abbr(registry, 'hfsp', 'hf skills preview')  # Fish line 1548
    abbr(registry, 'lsh', 'llama-server --help')  # Fish line 1554
    abbr(registry, 'lslsd', 'llama-server --list-devices')  # Fish line 1555
    abbr(registry, 'lsv', 'llama-server --version')  # Fish line 1556
    abbr(registry, 'lsc', 'llama-server --cache-list')  # Fish line 1557
    abbr(registry, 'ls_test_completions_stream', "http paxy.lan:8016/completions stream:=true max_tokens:=10 prompt='what is 11*2'")  # Fish line 1572
    abbr(registry, 'ls_test_completions_sync', "http paxy.lan:8016/completions stream:=false max_tokens:=100 prompt='what is 11*2'")  # Fish line 1573
    abbr(registry, 'ls_test_chat_stream', 'http paxy.lan:8016/chat/completions verbose:=true stream:=true max_tokens:=11 \'messages:=[ {"role": "user", "content": "what is 11*2"} ]\'')  # Fish line 1577
    abbr(registry, 'ls_test_chat_sync', 'http paxy.lan:8016/chat/completions verbose:=true stream:=false max_tokens:=100 \'messages:=[ {"role": "user", "content": "what is 11*2"} ]\'')  # Fish line 1578
    abbr(registry, 'olc', 'ollama create')  # Fish line 1582
    abbr(registry, 'olcp', 'ollama cp')  # Fish line 1583
    abbr(registry, 'ole', "export OLLAMA_HOST='ollama.lan:11434'")  # Fish line 1584
    abbr(registry, 'olh', 'ollama help')  # Fish line 1587
    abbr(registry, 'ollnaked', 'grc ollama list')  # Fish line 1589
    abbr(registry, 'oll', 'ollama list | awk \'{OFS="\\t" } /%/ { print $3$4,$1,$2,$5" "$6" "$7" "$8" "$9 }\' | sort -h | column -t | grcat conf.ollama_list', cursor_marker="%")  # Fish line 1593
    abbr(registry, 'ollqwen3coder', 'grc ollama list qwen3-coder')  # Fish line 1595
    abbr(registry, 'ollqwen25coder', 'grc ollama list qwen2.5-coder')  # Fish line 1596
    abbr(registry, 'ollqwen25', 'grc ollama list qwen2.5:')  # Fish line 1597
    abbr(registry, 'ollqwen3', 'grc ollama list qwen3:')  # Fish line 1598
    abbr(registry, 'ollgptoss', 'grc ollama list gpt-oss')  # Fish line 1599
    abbr(registry, 'olp', 'ollama pull')  # Fish line 1601
    abbr(registry, 'olps', 'ollama ps')  # Fish line 1602
    abbr(registry, 'olpush', 'ollama push')  # Fish line 1603
    abbr(registry, 'olr', 'ollama run --verbose')  # Fish line 1604
    abbr(registry, 'olrm', 'ollama rm')  # Fish line 1605
    abbr(registry, 'olsl', 'OLLAMA_NUM_PARALLEL=1 ollama serve 2>&1 | bat -pp -l log')  # Fish line 1612
    abbr(registry, 'olsld', 'OLLAMA_NUM_PARALLEL=1 OLLAMA_DEBUG=2 ollama serve 2>&1 | bat -pp -l log')  # Fish line 1613
    abbr(registry, 'olsg', "OLLAMA_NUM_PARALLEL=1 OLLAMA_HOST='http://0.0.0.0:11434' ollama serve 2>&1 | bat -pp -l log")  # Fish line 1615
    abbr(registry, 'olsgd', "OLLAMA_NUM_PARALLEL=1 OLLAMA_DEBUG=2 OLLAMA_HOST='http://0.0.0.0:11434' ollama serve 2>&1 | bat -pp -l log")  # Fish line 1616
    abbr(registry, 'olsq', 'ols_qwen')  # Fish line 1622
    abbr(registry, 'olsqd', 'ols_qwen_debug')  # Fish line 1623
    abbr(registry, 'olshow', 'grc ollama show')  # Fish line 1640
    abbr(registry, 'olshow_template', 'ollama show --template % | bat -l go', cursor_marker="%")  # Fish line 1641
    abbr(registry, 'olshow_modelfile', 'ollama show --modelfile % | bat -l Dockerfile', cursor_marker="%")  # Fish line 1642
    abbr(registry, 'anr', 'asciinema rec --overwrite test.cast')  # Fish line 2814
    abbr(registry, 'anp', 'asciinema play')  # Fish line 2815
    abbr(registry, 'anu', 'asciinema upload')  # Fish line 2816
    abbr(registry, 'anc', 'asciinema cat')  # Fish line 2817
    abbr(registry, 'aggo', fish_abbreviation('abbr_agg'))  # Fish line 2827
    abbr(registry, 'vllms', 'vllm serve')  # Fish line 2859
    abbr(registry, 'vllmb', 'vllm bench')  # Fish line 2862
    abbr(registry, 'vllmc', 'vllm chat')  # Fish line 2863
    abbr(registry, 'vllmg', 'vllm complete')  # Fish line 2864
    abbr(registry, 'tailf', 'tail -F -n 1000')  # Fish line 2867
    abbr(registry, 'tailF', 'tail -F -n 1000')  # Fish line 2868
    abbr(registry, 'tailn', 'tail -n 1000')  # Fish line 2869
    abbr(registry, 'tailr', 'tail -r')  # Fish line 2870
    abbr(registry, 'tt', 'trash_n_tail')  # Fish line 2872
    abbr(registry, 'tt_mcp_server_commands', 'tail -F ~/.local/state/mcp-server-commands/commands.log')  # Fish line 2895
    abbr(registry, 'tail_mcp_server_commands', 'tail -F ~/.local/state/mcp-server-commands/commands.log')  # Fish line 2896
    abbr(registry, 'commands_log_review', 'commands_log_executable_mode; commands_log_shell_mode')  # Fish line 2897
    abbr(registry, 'tt_agents_mcp_server', 'tail -F ~/.local/state/mcp-servers/agent.log')  # Fish line 2906
    abbr(registry, 'tt_ask_lang_server', 'trash_n_tail ~/.local/state/ask-openai/language.server.log')  # Fish line 2910
    abbr(registry, 'tail_ask_lang_server', 'tail -F ~/.local/state/ask-openai/language.server.log')  # Fish line 2911
    abbr(registry, 'tt_nvim_lsp_log', 'trash_n_tail ~/.local/state/nvim/lsp.log')  # Fish line 2913
    abbr(registry, 'tail_nvim_lsp_log', 'tail -F ~/.local/state/nvim/lsp.log')  # Fish line 2914
    abbr(registry, 'tt_streamdeck_wes', 'trash_n_tail ~/.hammerspoon/logs/streamdeck_keyboardmaestro_runner.log')  # Fish line 2916
    abbr(registry, 'tail_streamdeck_wes', 'tail -F ~/.hammerspoon/logs/streamdeck_keyboardmaestro_runner.log')  # Fish line 2917
    abbr(registry, 'tail_hardtime_logs', 'cat ~/.local/state/nvim/hardtime.nvim.log | cut -c34- | sort | uniq -c | sort')  # Fish line 2919
    abbr(registry, re.compile('tail\\d+'), fish_abbreviation('_taild'))  # Fish line 2926
    abbr(registry, 'yapfs', 'yapf --style-help')  # Fish line 2932
    abbr(registry, 'sh', '--style-help', position="anywhere", commands=('yapf',))  # Fish line 2933
    abbr(registry, 'wscatc', 'wscat --connect -L --slash --show-ping-pong ws://localhost:8000')  # Fish line 3035
    abbr(registry, 'wscatl', 'wscat --listen 8000')  # Fish line 3036
    abbr(registry, 'wscat_echo_org', 'wscat --connect -L --slash --show-ping-pong ws://echo.websocket.org')  # Fish line 3038
    abbr(registry, 'una', 'uname -a')  # Fish line 3042
    abbr(registry, 'hs', 'hs -C')  # Fish line 3055
    abbr(registry, 'hs_interactive', 'hs -C')  # Fish line 3056
    abbr(registry, 'hsq', 'hs -q')  # Fish line 3057
    abbr(registry, 'hs_clone_from_console', 'hs -C')  # Fish line 3061
    abbr(registry, 'hs_clone_to_console', 'hs -P')  # Fish line 3063
    abbr(registry, 'hsc', 'hs -c')  # Fish line 3071
    abbr(registry, 'hs_open_console', "hs -c 'hs.openConsole()'")  # Fish line 3072
    abbr(registry, 'hs_reload', "hs -c 'hs.openConsole(); hs.reload(); hs.console.clearConsole()'")  # Fish line 3073
    abbr(registry, 'hs_clear_console', "hs -c 'hs.console.clearConsole()'")  # Fish line 3074
    abbr(registry, 'hscq', 'hs -c -q')  # Fish line 3075
    abbr(registry, 'ct', 'ctags')  # Fish line 3080
    abbr(registry, 'ctags_stdout_only_lua', 'ctags --languages=lua -f -')  # Fish line 3081
    abbr(registry, 'ctl', 'ctags --list-%', cursor_marker="%")  # Fish line 3082
    abbr(registry, 'ctle', 'ctags --list-excludes')  # Fish line 3083
    abbr(registry, 'ctll', 'ctags --list-languages')  # Fish line 3084
    abbr(registry, 'ctlf', 'ctags --list-fields')  # Fish line 3085
    abbr(registry, 'ctlx', 'ctags --list-extras')  # Fish line 3086
    abbr(registry, 'ctags_stdout', 'ctags -f -')  # Fish line 3087
    abbr(registry, 'ctags_list_not_files', "cat tags  | sort | uniq | rg_grep --invert-match '\\.(zsh|lua|py|rs|c|md|json|vim|plist|js|ps1)' | bat -l csv")  # Fish line 3089
    abbr(registry, 'psse', "| sed -E 's/^[^{]*//' | jq", position="anywhere")  # Fish line 3316
    abbr(registry, 'pssec', "| sed -E 's/^[^{]*//' | jq --compact-output", position="anywhere")  # Fish line 3317
    abbr(registry, 'pdata', "| rg_grep -v ':data' | sed -E 's/^[^{]*//' | jq", position="anywhere")  # Fish line 3318
    abbr(registry, 'pb_copy_sse', "pbpaste | sed -E 's/^[^{]*//' | jq | pbcopy")  # Fish line 3322
    abbr(registry, 'pbsse', "pbpaste | sed -E 's/^[^{]*//' | jq")  # Fish line 3325
    abbr(registry, 'pbssec', "pbpaste | sed -E 's/^[^{]*//' | jq --compact-output")  # Fish line 3326
    abbr(registry, 'pbsse_verbose_prompt', "pbpaste | sed -E 's/^[^{]*//' | jq '.__verbose.prompt' -r")  # Fish line 3328
    abbr(registry, 'pbsse_verbose_prompt_harmony', "pbpaste | sed -E 's/^[^{]*//' | jq '.__verbose.prompt' -r | tree-sitter highlight --scope source.harmony")  # Fish line 3331
    abbr(registry, 'pbsse_verbose_content', "pbpaste | sed -E 's/^[^{]*//' | jq '.__verbose.content' -r")  # Fish line 3332
    abbr(registry, 'pbsse_verbose_raw_response', "pbpaste | sed -E 's/^[^{]*//' | jq '.__verbose.content' -r")  # Fish line 3333
    abbr(registry, 'pbsse1', "pbpaste | sed -E 's/^[^{]*//' | jq > input-messages.json")  # Fish line 3334
    abbr(registry, 'pbsse2', "pbpaste | sed -E 's/^[^{]*//' | jq > input-rendered-prompt.json")  # Fish line 3335
    abbr(registry, 'pbsse3', "pbpaste | sed -E 's/^[^{]*//' | jq > output-parsed-message.json")  # Fish line 3336
    abbr(registry, 'pbssetrace', 'view_trace (pbpaste | string replace --regex "[^{]*" "" | psub)')  # Fish line 3337
    abbr(registry, 'pbsse4', "pbpaste | string replace --regex '^\\w\\w\\w \\d\\d \\d\\d:\\d\\d:\\d\\d \\w+ llama-server\\[\\d+\\]: ' '' | string replace 'Parsing input with format GPT-OSS: ' '' > output-raw.harmony")  # Fish line 3342
    abbr(registry, 'llama_server_current_chat_template', 'curl paxy:8013/props | jq .chat_template --raw-output')  # Fish line 3354
    abbr(registry, '-S', '--sort-keys', position="anywhere", commands=('jq',))  # Fish line 3361
    abbr(registry, '-C', '--color-output', position="anywhere", commands=('jq',))  # Fish line 3362
    abbr(registry, '-c', '--compact-output', position="anywhere", commands=('jq',))  # Fish line 3363
    abbr(registry, '-r', '--raw-output', position="anywhere", commands=('jq',))  # Fish line 3364
    abbr(registry, '-j', '--join-output', position="anywhere", commands=('jq',))  # Fish line 3365
    abbr(registry, 'jqk', 'jq keys')  # Fish line 3367
    abbr(registry, 'sort_keys', 'jq --sort-keys', position="anywhere", commands=('jq',))  # Fish line 3370
    abbr(registry, 'not_null', '| select(.)', position="anywhere", commands=('jq',))  # Fish line 3371
    abbr(registry, 'yqy', 'yq --yaml-output')  # Fish line 3377
    abbr(registry, '-y', '--yaml-output', position="anywhere", commands=('yq',))  # Fish line 3379
    abbr(registry, '-c', '--compact-output', position="anywhere", commands=('yq',))  # Fish line 3380
    abbr(registry, '-r', '--raw-output', position="anywhere", commands=('yq',))  # Fish line 3381
    abbr(registry, 'clm', 'ANTHROPIC_BASE_URL="http://ask.lan:8012" claude --model Qwen/Qwen3-Coder-Next-GGUF:Q8_0')  # Fish line 3504
    abbr(registry, 'clr', 'claude --resume')  # Fish line 3505
    abbr(registry, 'cld', 'claude --dangerously-skip-permissions')  # Fish line 3506
    abbr(registry, '-h', '--help', position="anywhere", commands=('nix',))  # Fish line 3510
    abbr(registry, 'nixh', 'nix --help')  # Fish line 3511
    abbr(registry, 'nixpls', 'nix profile list')  # Fish line 3512
