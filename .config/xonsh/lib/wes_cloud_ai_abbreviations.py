"""Cloud Ai abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

import re

from wes_abbreviations import abbr
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


def register_cloud_ai_abbreviations():
    abbr('actw', fish_abbreviation('actw_expanded'))  # Fish line 1370
    abbr('azal', 'az account list --output table')  # Fish line 1451
    abbr('azall', 'az account list-locations --output table')  # Fish line 1452
    abbr('azrl', 'az resource list --output table')  # Fish line 1455
    abbr('azrs', 'az resource show --output table')  # Fish line 1456
    abbr('azgl', 'az group list --output table')  # Fish line 1458
    abbr('azwl', 'az webapp list --output table')  # Fish line 1461
    abbr('azasl', 'az appservice plan list --output table')  # Fish line 1462
    abbr('hfc', 'hf cache')  # Fish line 1511
    abbr('hfcls', 'hf cache ls --no-truncate --revisions')  # Fish line 1513
    abbr('hfcpr', 'hf cache prune')  # Fish line 1518
    abbr('hfcrm', 'hf cache rm')  # Fish line 1520
    abbr('hfcv', 'hf cache verify')  # Fish line 1521
    abbr('hfc_downloadInProgress', 'fd .downloadInProgress ~/.cache/huggingface/')  # Fish line 1522
    abbr('hfml', 'hf models ls')  # Fish line 1524
    abbr('hfmls', 'hf models ls --search')  # Fish line 1525
    abbr('hfmlsa', 'hf models ls --limit 30 --author')  # Fish line 1526
    abbr('hfmls_ggml_org', 'hf models ls --limit 30 --author ggml-org')  # Fish line 1527
    abbr('hfmls_ggml_org_qwen36', 'hf models ls --limit 30 --author ggml-org --search qwen3.6')  # Fish line 1529
    abbr('hfmls_ggml_org_qwen35', 'hf models ls --limit 30 --author ggml-org --search qwen3.5')  # Fish line 1530
    abbr('hfmls_qwen', 'hf models ls --limit 30 --author Qwen')  # Fish line 1531
    abbr('hfmls_qwen_qwen36', 'hf models ls --limit 30 --author Qwen --search qwen3.6')  # Fish line 1532
    abbr('hfmls_qwen_qwen35', 'hf models ls --limit 30 --author Qwen --search qwen3.5')  # Fish line 1533
    abbr('hfmi', 'hf models info')  # Fish line 1535
    abbr('hfdl', 'hf datasets ls')  # Fish line 1537
    abbr('hfdls', 'hf datasets ls --search')  # Fish line 1538
    abbr('hfdla', 'hf datasets ls --author')  # Fish line 1539
    abbr('hfdinfo', 'hf datasets info')  # Fish line 1540
    abbr('hfcols', 'hf collections ls --owner')  # Fish line 1542
    abbr('hfcols_ggml_org', 'hf collections ls --owner ggml-org')  # Fish line 1543
    abbr('hfcols_qwen', 'hf collections ls --owner Qwen')  # Fish line 1544
    abbr('hfcoi', 'hf collections info % | jq ".items | .[] | [ .item_type, .item_id ] " --compact-output')  # Fish line 1545
    abbr('hfsp', 'hf skills preview')  # Fish line 1548
    abbr('lsh', 'llama-server --help')  # Fish line 1554
    abbr('lslsd', 'llama-server --list-devices')  # Fish line 1555
    abbr('lsv', 'llama-server --version')  # Fish line 1556
    abbr('lsc', 'llama-server --cache-list')  # Fish line 1557
    abbr('ls_test_completions_stream', "http paxy.lan:8016/completions stream:=true max_tokens:=10 prompt='what is 11*2'")  # Fish line 1572
    abbr('ls_test_completions_sync', "http paxy.lan:8016/completions stream:=false max_tokens:=100 prompt='what is 11*2'")  # Fish line 1573
    abbr('ls_test_chat_stream', 'http paxy.lan:8016/chat/completions verbose:=true stream:=true max_tokens:=11 \'messages:=[ {"role": "user", "content": "what is 11*2"} ]\'')  # Fish line 1577
    abbr('ls_test_chat_sync', 'http paxy.lan:8016/chat/completions verbose:=true stream:=false max_tokens:=100 \'messages:=[ {"role": "user", "content": "what is 11*2"} ]\'')  # Fish line 1578
    abbr('olc', 'ollama create')  # Fish line 1582
    abbr('olcp', 'ollama cp')  # Fish line 1583
    abbr('ole', "export OLLAMA_HOST='ollama.lan:11434'")  # Fish line 1584
    abbr('olh', 'ollama help')  # Fish line 1587
    abbr('ollnaked', 'grc ollama list')  # Fish line 1589
    abbr('oll', 'ollama list | awk \'{OFS="\\t" } /%/ { print $3$4,$1,$2,$5" "$6" "$7" "$8" "$9 }\' | sort -h | column -t | grcat conf.ollama_list', cursor_marker="%")  # Fish line 1593
    abbr('ollqwen3coder', 'grc ollama list qwen3-coder')  # Fish line 1595
    abbr('ollqwen25coder', 'grc ollama list qwen2.5-coder')  # Fish line 1596
    abbr('ollqwen25', 'grc ollama list qwen2.5:')  # Fish line 1597
    abbr('ollqwen3', 'grc ollama list qwen3:')  # Fish line 1598
    abbr('ollgptoss', 'grc ollama list gpt-oss')  # Fish line 1599
    abbr('olp', 'ollama pull')  # Fish line 1601
    abbr('olps', 'ollama ps')  # Fish line 1602
    abbr('olpush', 'ollama push')  # Fish line 1603
    abbr('olr', 'ollama run --verbose')  # Fish line 1604
    abbr('olrm', 'ollama rm')  # Fish line 1605
    abbr('olsl', 'OLLAMA_NUM_PARALLEL=1 ollama serve 2>&1 | bat -pp -l log')  # Fish line 1612
    abbr('olsld', 'OLLAMA_NUM_PARALLEL=1 OLLAMA_DEBUG=2 ollama serve 2>&1 | bat -pp -l log')  # Fish line 1613
    abbr('olsg', "OLLAMA_NUM_PARALLEL=1 OLLAMA_HOST='http://0.0.0.0:11434' ollama serve 2>&1 | bat -pp -l log")  # Fish line 1615
    abbr('olsgd', "OLLAMA_NUM_PARALLEL=1 OLLAMA_DEBUG=2 OLLAMA_HOST='http://0.0.0.0:11434' ollama serve 2>&1 | bat -pp -l log")  # Fish line 1616
    abbr('olsq', 'ols_qwen')  # Fish line 1622
    abbr('olsqd', 'ols_qwen_debug')  # Fish line 1623
    abbr('olshow', 'grc ollama show')  # Fish line 1640
    abbr('olshow_template', 'ollama show --template % | bat -l go', cursor_marker="%")  # Fish line 1641
    abbr('olshow_modelfile', 'ollama show --modelfile % | bat -l Dockerfile', cursor_marker="%")  # Fish line 1642
    abbr('anr', 'asciinema rec --overwrite test.cast')  # Fish line 2814
    abbr('anp', 'asciinema play')  # Fish line 2815
    abbr('anu', 'asciinema upload')  # Fish line 2816
    abbr('anc', 'asciinema cat')  # Fish line 2817
    abbr('aggo', fish_abbreviation('abbr_agg'))  # Fish line 2827
    abbr('vllms', 'vllm serve')  # Fish line 2859
    abbr('vllmb', 'vllm bench')  # Fish line 2862
    abbr('vllmc', 'vllm chat')  # Fish line 2863
    abbr('vllmg', 'vllm complete')  # Fish line 2864
    abbr('tailf', 'tail -F -n 1000')  # Fish line 2867
    abbr('tailF', 'tail -F -n 1000')  # Fish line 2868
    abbr('tailn', 'tail -n 1000')  # Fish line 2869
    abbr('tailr', 'tail -r')  # Fish line 2870
    abbr('tt', 'trash_n_tail')  # Fish line 2872
    abbr('tt_mcp_server_commands', 'tail -F ~/.local/state/mcp-server-commands/commands.log')  # Fish line 2895
    abbr('tail_mcp_server_commands', 'tail -F ~/.local/state/mcp-server-commands/commands.log')  # Fish line 2896
    abbr('commands_log_review', 'commands_log_executable_mode; commands_log_shell_mode')  # Fish line 2897
    abbr('tt_agents_mcp_server', 'tail -F ~/.local/state/mcp-servers/agent.log')  # Fish line 2906
    abbr('tt_ask_lang_server', 'trash_n_tail ~/.local/state/ask-openai/language.server.log')  # Fish line 2910
    abbr('tail_ask_lang_server', 'tail -F ~/.local/state/ask-openai/language.server.log')  # Fish line 2911
    abbr('tt_nvim_lsp_log', 'trash_n_tail ~/.local/state/nvim/lsp.log')  # Fish line 2913
    abbr('tail_nvim_lsp_log', 'tail -F ~/.local/state/nvim/lsp.log')  # Fish line 2914
    abbr('tt_streamdeck_wes', 'trash_n_tail ~/.hammerspoon/logs/streamdeck_keyboardmaestro_runner.log')  # Fish line 2916
    abbr('tail_streamdeck_wes', 'tail -F ~/.hammerspoon/logs/streamdeck_keyboardmaestro_runner.log')  # Fish line 2917
    abbr('tail_hardtime_logs', 'cat ~/.local/state/nvim/hardtime.nvim.log | cut -c34- | sort | uniq -c | sort')  # Fish line 2919
    abbr(re.compile('tail\\d+'), fish_abbreviation('_taild'))  # Fish line 2926
    abbr('yapfs', 'yapf --style-help')  # Fish line 2932
    abbr('sh', '--style-help', position="anywhere", commands=('yapf',))  # Fish line 2933
    abbr('wscatc', 'wscat --connect -L --slash --show-ping-pong ws://localhost:8000')  # Fish line 3035
    abbr('wscatl', 'wscat --listen 8000')  # Fish line 3036
    abbr('wscat_echo_org', 'wscat --connect -L --slash --show-ping-pong ws://echo.websocket.org')  # Fish line 3038
    abbr('una', 'uname -a')  # Fish line 3042
    abbr('hs', 'hs -C')  # Fish line 3055
    abbr('hs_interactive', 'hs -C')  # Fish line 3056
    abbr('hsq', 'hs -q')  # Fish line 3057
    abbr('hs_clone_from_console', 'hs -C')  # Fish line 3061
    abbr('hs_clone_to_console', 'hs -P')  # Fish line 3063
    abbr('hsc', 'hs -c')  # Fish line 3071
    abbr('hs_open_console', "hs -c 'hs.openConsole()'")  # Fish line 3072
    abbr('hs_reload', "hs -c 'hs.openConsole(); hs.reload(); hs.console.clearConsole()'")  # Fish line 3073
    abbr('hs_clear_console', "hs -c 'hs.console.clearConsole()'")  # Fish line 3074
    abbr('hscq', 'hs -c -q')  # Fish line 3075
    abbr('ct', 'ctags')  # Fish line 3080
    abbr('ctags_stdout_only_lua', 'ctags --languages=lua -f -')  # Fish line 3081
    abbr('ctl', 'ctags --list-%', cursor_marker="%")  # Fish line 3082
    abbr('ctle', 'ctags --list-excludes')  # Fish line 3083
    abbr('ctll', 'ctags --list-languages')  # Fish line 3084
    abbr('ctlf', 'ctags --list-fields')  # Fish line 3085
    abbr('ctlx', 'ctags --list-extras')  # Fish line 3086
    abbr('ctags_stdout', 'ctags -f -')  # Fish line 3087
    abbr('ctags_list_not_files', "cat tags  | sort | uniq | rg_grep --invert-match '\\.(zsh|lua|py|rs|c|md|json|vim|plist|js|ps1)' | bat -l csv")  # Fish line 3089
    abbr('psse', "| sed -E 's/^[^{]*//' | jq", position="anywhere")  # Fish line 3316
    abbr('pssec', "| sed -E 's/^[^{]*//' | jq --compact-output", position="anywhere")  # Fish line 3317
    abbr('pdata', "| rg_grep -v ':data' | sed -E 's/^[^{]*//' | jq", position="anywhere")  # Fish line 3318
    abbr('pb_copy_sse', "pbpaste | sed -E 's/^[^{]*//' | jq | pbcopy")  # Fish line 3322
    abbr('pbsse', "pbpaste | sed -E 's/^[^{]*//' | jq")  # Fish line 3325
    abbr('pbssec', "pbpaste | sed -E 's/^[^{]*//' | jq --compact-output")  # Fish line 3326
    abbr('pbsse_verbose_prompt', "pbpaste | sed -E 's/^[^{]*//' | jq '.__verbose.prompt' -r")  # Fish line 3328
    abbr('pbsse_verbose_prompt_harmony', "pbpaste | sed -E 's/^[^{]*//' | jq '.__verbose.prompt' -r | tree-sitter highlight --scope source.harmony")  # Fish line 3331
    abbr('pbsse_verbose_content', "pbpaste | sed -E 's/^[^{]*//' | jq '.__verbose.content' -r")  # Fish line 3332
    abbr('pbsse_verbose_raw_response', "pbpaste | sed -E 's/^[^{]*//' | jq '.__verbose.content' -r")  # Fish line 3333
    abbr('pbsse1', "pbpaste | sed -E 's/^[^{]*//' | jq > input-messages.json")  # Fish line 3334
    abbr('pbsse2', "pbpaste | sed -E 's/^[^{]*//' | jq > input-rendered-prompt.json")  # Fish line 3335
    abbr('pbsse3', "pbpaste | sed -E 's/^[^{]*//' | jq > output-parsed-message.json")  # Fish line 3336
    abbr('pbssetrace', 'view_trace (pbpaste | string replace --regex "[^{]*" "" | psub)')  # Fish line 3337
    abbr('pbsse4', "pbpaste | string replace --regex '^\\w\\w\\w \\d\\d \\d\\d:\\d\\d:\\d\\d \\w+ llama-server\\[\\d+\\]: ' '' | string replace 'Parsing input with format GPT-OSS: ' '' > output-raw.harmony")  # Fish line 3342
    abbr('llama_server_current_chat_template', 'curl paxy:8013/props | jq .chat_template --raw-output')  # Fish line 3354
    abbr('-S', '--sort-keys', position="anywhere", commands=('jq',))  # Fish line 3361
    abbr('-C', '--color-output', position="anywhere", commands=('jq',))  # Fish line 3362
    abbr('-c', '--compact-output', position="anywhere", commands=('jq',))  # Fish line 3363
    abbr('-r', '--raw-output', position="anywhere", commands=('jq',))  # Fish line 3364
    abbr('-j', '--join-output', position="anywhere", commands=('jq',))  # Fish line 3365
    abbr('jqk', 'jq keys')  # Fish line 3367
    abbr('sort_keys', 'jq --sort-keys', position="anywhere", commands=('jq',))  # Fish line 3370
    abbr('not_null', '| select(.)', position="anywhere", commands=('jq',))  # Fish line 3371
    abbr('yqy', 'yq --yaml-output')  # Fish line 3377
    abbr('-y', '--yaml-output', position="anywhere", commands=('yq',))  # Fish line 3379
    abbr('-c', '--compact-output', position="anywhere", commands=('yq',))  # Fish line 3380
    abbr('-r', '--raw-output', position="anywhere", commands=('yq',))  # Fish line 3381
    abbr('clm', 'ANTHROPIC_BASE_URL="http://ask.lan:8012" claude --model Qwen/Qwen3-Coder-Next-GGUF:Q8_0')  # Fish line 3504
    abbr('clr', 'claude --resume')  # Fish line 3505
    abbr('cld', 'claude --dangerously-skip-permissions')  # Fish line 3506
    abbr('-h', '--help', position="anywhere", commands=('nix',))  # Fish line 3510
    abbr('nixh', 'nix --help')  # Fish line 3511
    abbr('nixpls', 'nix profile list')  # Fish line 3512
