if command -q act

    function actw_expanded

        # if not in repo root, prepend a cd too, mostly as a reminder to avoid pathing issues to the workflow files and also issues when run act inside a nested dir:
        if test (pwd) != (_repo_root)
            echo -n "cd \$(_repo_root); "
        end

        echo act --reuse --workflows .github/workflows/!

    end

    abbr --add actw --set-cursor --function actw_expanded

    # GENERATED COMPLETIONS (finagled chatgpt to spit this out):
    #
    # function generate_completions_from_help
    #     for line in (act --help | rg_grep -oE "\-\-[a-zA-Z0-9-]+")
    #         set option (echo $line | sed 's/--//')
    #         echo complete -c act -l $option
    #     end
    # end
    #
    # generate_completions_from_help
    #
    complete -c act -l action-cache-path -d "Defines the path where the actions get cached and host workspaces created."
    complete -c act -l action-offline-mode -d "If action contents exist, it will not be fetched or pulled again."
    complete -c act -l actor -s a -d "User that triggered the event."
    complete -c act -l artifact-server-addr -d "Defines the address to which the artifact server binds."
    complete -c act -l artifact-server-path -d "Defines the path where the artifact server stores uploads and downloads."
    complete -c act -l artifact-server-port -d "Defines the port where the artifact server listens."
    complete -c act -l bind -s b -d "Bind working directory to container, rather than copy."
    complete -c act -l bug-report -d "Display system information for bug report."
    complete -c act -l cache-server-addr -d "Defines the address to which the cache server binds."
    complete -c act -l cache-server-path -d "Defines the path where the cache server stores caches."
    complete -c act -l cache-server-port -d "Defines the port where the cache server listens."
    complete -c act -l container-architecture -d "Architecture which should be used to run containers."
    complete -c act -l container-cap-add -d "Kernel capabilities to add to the workflow containers."
    complete -c act -l container-cap-drop -d "Kernel capabilities to remove from the workflow containers."
    complete -c act -l container-daemon-socket -d "URI to Docker Engine socket."
    complete -c act -l container-options -d "Custom docker container options for the job container."
    complete -c act -l defaultbranch -d "The name of the main branch."
    complete -c act -l detect-event -d "Use first event type from workflow as the event that triggered the workflow."
    complete -c act -l directory -s C -d "Working directory."
    complete -c act -l dryrun -s n -d "Dryrun mode."
    complete -c act -l env -d "Environment variables to make available to actions."
    complete -c act -l env-file -d "Environment file to read and use as env in the containers."
    complete -c act -l eventpath -s e -d "Path to event JSON file."
    complete -c act -l github-instance -d "GitHub instance to use, not for GitHub Enterprise Server."
    complete -c act -l graph -s g -d "Draw workflows."
    complete -c act -l help -s h -d "Help for act."
    complete -c act -l input -d "Action input to make available to actions."
    complete -c act -l input-file -d "Input file to read and use as action input."
    complete -c act -l insecure-secrets -d "Does not hide secrets while printing logs."
    complete -c act -l job -s j -d "Run a specific job ID."
    complete -c act -l json -d "Output logs in json format."
    complete -c act -l list -s l -d "List workflows."
    complete -c act -l local-repository -d "Replaces the specified repository and ref with a local folder."
    complete -c act -l log-prefix-job-id -d "Output the job id within non-json logs."
    complete -c act -l matrix -d "Specify which matrix configuration to include."
    complete -c act -l network -d "Sets a docker network name."
    complete -c act -l no-cache-server -d "Disable cache server."
    complete -c act -l no-recurse -d "Disable running workflows from subdirectories."
    complete -c act -l workflows -d "Path to workflow files."
    complete -c act -l no-skip-checkout -d "Do not skip actions/checkout."
    complete -c act -l platform -s P -d "Custom image to use per platform."
    complete -c act -l privileged -d "Use privileged mode."
    complete -c act -l pull -s p -d "Pull docker image(s) even if already present."
    complete -c act -l quiet -s q -d "Disable logging of output from steps."
    complete -c act -l rebuild -d "Rebuild local action docker image(s) even if already present."
    complete -c act -l remote-name -d "Git remote name used to retrieve URL of git repo."
    complete -c act -l replace-ghe-action-token-with-github-com -d "Set personal access token for private actions on GitHub."
    complete -c act -l replace-ghe-action-with-github-com -d "Allow specified actions from GitHub on GitHub Enterprise Server."
    complete -c act -l reuse -s r -d "Don't remove container(s) on successfully completed workflows."
    complete -c act -l rm -d "Automatically remove container(s)/volume(s) after a workflow(s) failure."
    complete -c act -l secret -s s -d "Secret to make available to actions."
    complete -c act -l secret-file -d "File with list of secrets to read from."
    complete -c act -l use-gitignore -d "Controls whether paths in .gitignore should be copied into container."
    complete -c act -l use-new-action-cache -d "Enable using the new Action Cache for storing Actions locally."
    complete -c act -l userns -d "User namespace to use."
    complete -c act -l var -d "Variable to make available to actions."
    complete -c act -l var-file -d "File with list of vars to read from."
    complete -c act -l verbose -s v -d "Verbose output."
    complete -c act -l version -d "Version for act."
    complete -c act -l watch -s w -d "Watch the contents of the local repo and run when files change."
    complete -c act -l workflows -s W -d "Specify path to workflow files."

end

if command -q az

    # *** do not try to add upfront, lol!

    abbr azal 'az account list --output table' # subscriptions
    abbr azall 'az account list-locations --output table' # locations

    # resources:
    abbr azrl 'az resource list --output table' # resources
    abbr azrs 'az resource show --output table' # resource show
    # resource groups:
    abbr azgl 'az group list --output table'

    # app services
    abbr azwl 'az webapp list --output table' # webapps
    abbr azasl 'az appservice plan list --output table' # service plans

end

# ** search downloaded model caches (clean up space)

function rg_cached_models --argument-names search_regex
    set _cache_llama_server ~/.cache/llama.cpp
    set _cache_hf ~/.cache/huggingface
    set _cache_ollama ~/.ollama
    set _cache_lm_studio ~/.cache/lm-studio/models

    log_blankline

    log_ --blue "## llama-server $_cache_llama_server"
    fd --unrestricted $search_regex $_cache_llama_server
    log_blankline

    log_ --blue "## huggingface $_cache_hf"
    fd --unrestricted $search_regex $_cache_hf
    log_blankline

    log_ --blue "## ollama $_cache_ollama"
    fd --unrestricted $search_regex $_cache_ollama
    log_blankline

    log_ --blue "## LM Studio $_cache_lm_studio"
    fd --unrestricted $search_regex $_cache_lm_studio
    log_blankline

end

# ** llama-cpp / llama-server related

# * USE pipx install hf
# abbr huggingface-cli hf
# function hf
#     # FYI new workflow appears to be:
#     #   hf cache ls
#     #   hf cache rm user/repo
#
#     # TODO later
#     #   hf --show-completion #... I can put this in ~/.config/fish/completions/hf.fish ... issue is the hf command doesn't exist so it can't generate completions w/o this function... ciruclar loop at best... FUUU
#
#     # FYI (no longer need [cli] extras)
#     # stop using arcane 0.36 ... newer has completions btw, transformers 4.X is tied to <1 btw so not gonna install newer in most venvs until 5 is RC'd
#     uv tool run --from 'huggingface-hub>=1.1.7' hf $argv
# end

abbr hfc "hf cache"
#
abbr hfcls "hf cache ls --no-truncate --revisions" # show all revisions (aka refs) not just current
# cache is stored in refs/blobs/snapshots dirs
#  old revisions are like dangling pointers (no refs/* entry)
#
# use prune to remove old revisions so you don't have to hunt those down by hand
abbr hfcpr "hf cache prune"
#
abbr hfcrm "hf cache rm" # can pass revision sha to rm
abbr hfcv "hf cache verify"
abbr hfc_downloadInProgress "fd .downloadInProgress ~/.cache/huggingface/" # reminder abbr

abbr hfml "hf models ls"
abbr hfmls "hf models ls --search"
abbr hfmlsa "hf models ls --limit 30 --author"
abbr hfmls_ggml_org "hf models ls --limit 30 --author ggml-org"
abbr hfmls_ggml_org "hf models ls --limit 30 --author ggml-org"
abbr hfmls_ggml_org_qwen36 "hf models ls --limit 30 --author ggml-org --search qwen3.6"
abbr hfmls_ggml_org_qwen35 "hf models ls --limit 30 --author ggml-org --search qwen3.5"
abbr hfmls_qwen "hf models ls --limit 30 --author Qwen"
abbr hfmls_qwen_qwen36 "hf models ls --limit 30 --author Qwen --search qwen3.6"
abbr hfmls_qwen_qwen35 "hf models ls --limit 30 --author Qwen --search qwen3.5"

abbr hfmi "hf models info"

abbr hfdl "hf datasets ls"
abbr hfdls "hf datasets ls --search"
abbr hfdla "hf datasets ls --author"
abbr hfdinfo "hf datasets info"

abbr hfcols "hf collections ls --owner"
abbr hfcols_ggml_org "hf collections ls --owner ggml-org"
abbr hfcols_qwen "hf collections ls --owner Qwen"
abbr hfcoi "hf collections info % | jq \".items | .[] | [ .item_type, .item_id ] \" --compact-output"

# TODO look into skills, seems to be a way to see skills (maybe for an agent to run this command to dump instructions?)
abbr hfsp "hf skills preview"

if command -q llama-server
    # https://github.com/ggml-org/llama.cpp/blob/056eb745/common/arg.cpp#L1424-L1431
    # n_batch == https://github.com/ggml-org/llama.cpp/blob/056eb745/common/arg.cpp#L1442-L1448

    abbr lsh "llama-server --help"
    abbr lslsd "llama-server --list-devices"
    abbr lsv "llama-server --version"
    abbr lsc "llama-server --cache-list"

end

# * llama-server completion testers for rapid checking
set _ls_test_host paxy.lan:8016
set --local _ls_http 'http $_ls_test_host' # FYI AFAICT verbose only works on chat/completions but is ok to always pass
# FYI := means treat value as json literal (i.e. numbers/booleans)
# keep the prompt/messages as last arg so it is easier to edit
# use max_tokens=10 so we don't get a ton of SSEs in streaming + fast response
# one use is to review returned SSE structures
#
# FYI same as /v1/completions
#  TODO is verbose not a param on legacy /completions?
set --local _ls_prompt "'prompt=what is 11*2'"
abbr ls_test_completions_stream "$_ls_http/completions stream:=true max_tokens:=10 $_ls_prompt"
abbr ls_test_completions_sync "$_ls_http/completions stream:=false max_tokens:=100 $_ls_prompt"
#
# FYI same as /v1/chat/completions
set --local _ls_messages messages:='[ {"role": "user", "content": "what is 11*2"} ]'
abbr ls_test_chat_stream "$_ls_http/chat/completions verbose:=true stream:=true max_tokens:=11 '$_ls_messages'"
abbr ls_test_chat_sync "$_ls_http/chat/completions verbose:=true stream:=false max_tokens:=100 '$_ls_messages'"
# verbose => returns __verbose object

if command -q ollama
    abbr olc "ollama create"
    abbr olcp "ollama cp"
    abbr ole "export OLLAMA_HOST=ollama.lan:11434"

    # * list
    abbr olh "ollama help"
    #
    abbr ollnaked "grc ollama list"
    # until I get colors worked out so they're not positional (i.e. column X) then I'll default to bat coloring:
    # abbr --set-cursor -- oll 'ollama list | awk \'{OFS="\t" } /%/ { print $3$4,$1,$2,$5" "$6" "$7" "$8" "$9 }\' | sort -h | bat -l tsv --color=always | column -t'
    # FYI CURSOR is between // in awk so I can filter too!!!
    abbr --set-cursor -- oll 'ollama list | awk \'{OFS="\t" } /%/ { print $3$4,$1,$2,$5" "$6" "$7" "$8" "$9 }\' | sort -h | column -t | grcat conf.ollama_list'
    #
    abbr ollqwen3coder "grc ollama list qwen3-coder"
    abbr ollqwen25coder "grc ollama list qwen2.5-coder"
    abbr ollqwen25 "grc ollama list qwen2.5:"
    abbr ollqwen3 "grc ollama list qwen3:"
    abbr ollgptoss "grc ollama list gpt-oss"

    abbr olp "ollama pull"
    abbr olps "ollama ps"
    abbr olpush "ollama push"
    abbr olr "ollama run --verbose"
    abbr olrm "ollama rm"

    # PRN - use grc with ollama serve too and write my own coloring config (have claude do it)... do this if I dislike using bat for this
    set -l _ollama_serve "ollama serve 2>&1 | bat -pp -l log" # -pp to disable pager and use plain style (no line numbers).. w/o disable pager, on mac my pager setup prohibits streaming somehow (anyways just use this always)
    # OLLAMA_NUM_PARALLEL is to ensure maximum context size for a single request n_ctx (not split up by --parallel, which defaults to 4 on smaller qwen models)
    # OLLAMA_CONTEXT_LENGTH=8192 - num_ctx/n_ctx defaults to 2048... leads to truncation, set this here for OpenAI APIS that don't allow it as a parameter on a request
    # OLLAMA_KEEP_ALIVE=30m
    abbr olsl "OLLAMA_NUM_PARALLEL=1 $_ollama_serve"
    abbr olsld "OLLAMA_NUM_PARALLEL=1 OLLAMA_DEBUG=2 $_ollama_serve"
    #
    abbr olsg "OLLAMA_NUM_PARALLEL=1 OLLAMA_HOST='http://0.0.0.0:11434' $_ollama_serve"
    abbr olsgd "OLLAMA_NUM_PARALLEL=1 OLLAMA_DEBUG=2 OLLAMA_HOST='http://0.0.0.0:11434' $_ollama_serve"
    #
    # * ollama config code: https://github.com/ollama/ollama/blob/main/envconfig/config.go
    #    i.e. OLLAMA_KEEP_ALIVE=10m0s
    #
    # I am starting to understand the value of just serving a single model at a time (per endpoint)... i.e. to control params through env vars and not worry about model to model differences
    abbr olsq ols_qwen
    abbr olsqd ols_qwen_debug
    set _ollama_qwen "OLLAMA_CONTEXT_LENGTH=8192 OLLAMA_KEEP_ALIVE=10m OLLAMA_NUM_PARALLEL=4 OLLAMA_HOST='http://0.0.0.0:11434' eval $_ollama_serve"
    function ols_qwen_debug
        # FYI need new "TRACE" level OLLAMA_DEBUG=2 (previously =1 worked) to see prompts: https://github.com/ollama/ollama/pull/10650
        set cmd "OLLAMA_DEBUG=2 $_ollama_qwen"
        echo "$cmd\n" | bat -l fish
        eval $cmd
    end
    function ols_qwen
        set cmd "$_ollama_qwen"
        echo "$cmd\n" | bat -l fish
        eval $cmd
        # 4 requests @ 8k tokens each
        # TODO RoPE scaling params and/or impact on num_ctx?
        # model has n_ctx_training=32k but it is supposedly able to handle up to 128K tokens
    end

    abbr olshow "grc ollama show"
    abbr --set-cursor olshow_template "ollama show --template % | bat -l go" # go, jinja both seem ok
    abbr --set-cursor olshow_modelfile "ollama show --modelfile % | bat -l Dockerfile"
end

# TODO point cd => cd2?
function cd2
    # --description "cd improved"

    # if file passed, cd to dirname
    #   cd2 /Users/wes/repos/github/g0t4/dotfiles/foo.bar
    #     => cd /Users/wes/repos/github/g0t4/dotfiles
    # if path has spaces, don't need to quote it
    #   cd2 ~/Library/Application Support/iTerm2/Scripts
    #     => cd ~/Library/Application\ Support/iTerm2/Scripts
    # if path is relative to current user HOME dir then don't require ~ or $HOME prefix, try them for them:
    #   cd Library/Application Support/iTerm2/Scripts
    #     => cd ~/Library/Application\ Support/iTerm2/Scripts
    set path "$argv"
    if test -f $path
        # echo "File found: $path"
        set path (dirname $path)
    end
    # echo "cd2 $path"
    if test -d $path
        cd $path
    else if test -d $HOME/$path
        cd $HOME/$path
    else
        echo "Directory not found: $dir"
    end
end

# *** asciinema
abbr anr 'asciinema rec --overwrite test.cast' # PRN remake in fish:    abbr --set-cursor --add anr 'asciinema rec --overwrite %.cast'
abbr anp 'asciinema play'
abbr anu 'asciinema upload'
abbr anc 'asciinema cat'

function abbr_agg
    set -l cast_file *.cast
    if test -z "$cast_file"
        echo "no cast files"
        return
    end
    echo "agg --font-size 20 --font-family 'SauceCodePro Nerd Font' --theme 17181d,c7b168,555a6c,dc3d6f,9ed279,fae67f,469cd0,8b47e5,61d2b8,c229cf" $cast_file $cast_file.gif
end
abbr aggo --function abbr_agg

# NOTES about ROWS/COLUMNS:
# - check current size with: echo lines: $LINES cols: $COLUMNS
# ! *** prefer resize terminal before recording and asciinema will capture $ROWS $COLUMNS and just works on export then => dry run commands and see how they appear with constraints (ie upper left quarter of screen position window gives smaller window thats probably ideal for sharing a terminal gif recording)
#  *** OR `asciinema rec --rows X --cols Y...` works too though can be weird if smaller than actual terminal, esp if output would overflow the limits you place in --rows/--cols so best not to use this just set cols/rows by resizing window
#  IF YOU set agg's --cols/rows < actual cols/rows (in cast file) then you get a % and new lines in agg gif output

## agg
# PRN does agg support a config file? upon cursory inspection of repo I didn't see any documented nor in brief code review
#
# brew install agg
#
# config:
# --font-size 20+/--line-height
#   --font-dir/--font-family
#     mac:    --font-family 'SauceCodePro Nerd Font'
# --rows X / --cols Y
# --theme asciinema, dracula, monokai, solarized-dark, solarized-light, custom
# --speed 1.0
# --idle-time-limit 5.0 / --last-frame-delay 3.0
#   my terminal dark    --theme 17181d,c7b168,555a6c,dc3d6f,9ed279,fae67f,469cd0,8b47e5,61d2b8,c229cf
#
#
## asciicast2gif retired
#   https://github.com/asciinema/asciicast2gif
#   alias asciicast2gif='docker run --rm -v $PWD:/data asciinema/asciicast2gif'
#   successors:
#   - listed by asciicast2gif repo: https://github.com/asciinema/agg
#       nix! flake!
#   - copilot suggests: try ttygif?

abbr vllms "vllm serve"
# PRN some common args for vllm serve?
# abbr vllmsd "vllm serve --download-dir "
abbr vllmb "vllm bench"
abbr vllmc "vllm chat"
abbr vllmg "vllm complete"

# *** tail
abbr tailf 'tail -F -n 1000'
abbr tailF 'tail -F -n 1000'
abbr tailn 'tail -n 1000'
abbr tailr 'tail -r' # reverse order
# *** frequently tailed files
abbr tt trash_n_tail
# trash+tail b/c these quickly become unruly in size... I should setup truncation
abbr tt_xonsh "trash_n_tail -F ~/.local/state/xonsh/xonsh.log"
abbr tt_devtools_universal trash_n_tail ~/.local/share/devtools/universal.log
abbr tt_devtools_hammerspoons trash_n_tail ~/.local/share/devtools/hammerspoons.log
abbr tt_devtools_launcher trash_n_tail ~/.local/share/devtools/launcher.log

#
# for now I want to keep the commands.log, maybe go back to trash_n_tail later on, for now leave tt as tail -F too:
abbr tt_mcp_server_commands 'tail -F ~/.local/state/mcp-server-commands/commands.log'
abbr tail_mcp_server_commands 'tail -F ~/.local/state/mcp-server-commands/commands.log'
abbr commands_log_review "commands_log_executable_mode; commands_log_shell_mode"
function commands_log_executable_mode
    cat ~/.local/state/mcp-server-commands/commands.log | rg_grep run_process | rg_grep '"argv":'
end

function commands_log_shell_mode
    cat ~/.local/state/mcp-server-commands/commands.log | rg_grep run_process | rg_grep '"command_line":'
end
# delegate tool / agents MCP server
abbr tt_agents_mcp_server 'tail -F ~/.local/state/mcp-servers/agent.log'
# TODO other files here like traces?

#
abbr tt_ask_lang_server 'trash_n_tail ~/.local/state/ask-openai/language.server.log' # python LS
abbr tail_ask_lang_server 'tail -F ~/.local/state/ask-openai/language.server.log' # python LS
#
abbr tt_nvim_lsp_log 'trash_n_tail ~/.local/state/nvim/lsp.log' # nvim lsp logs
abbr tail_nvim_lsp_log 'tail -F ~/.local/state/nvim/lsp.log' # nvim lsp logs
#
abbr tt_streamdeck_wes 'trash_n_tail ~/.hammerspoon/logs/streamdeck_keyboardmaestro_runner.log'
abbr tail_streamdeck_wes 'tail -F ~/.hammerspoon/logs/streamdeck_keyboardmaestro_runner.log'
#
abbr tail_hardtime_logs 'cat ~/.local/state/nvim/hardtime.nvim.log | cut -c34- | sort | uniq -c | sort'
function trash_n_tail
    trash $argv
    tail -F $argv
end

# tail10<space> => tail -n 10
abbr taild --regex 'tail\d+' --function _taild
function _taild
    string replace tail 'tail -n ' $argv[1]
end

# do not use if command -q b/c yapf is often installed per venv
abbr -- yapfs "yapf --style-help"
abbr --command yapf -- sh --style-help

# * idea is to have rebuilders listed here
function rebuild_llama_cpp

    set llama_dir ~/repos/github/ggml-org/llama.cpp
    if not test -d $llama_dir
        echo "llama.cpp not checked out, aborting..."
        return 1
    end

    if not cd $llama_dir 2>/dev/null
        echo "Failed to change directory to $llama_dir"
        return 1
    end

    # git fetch origin
    git pull --rebase
    # show any commits reachable by `origin` (upstream) and not (^) readable by `^HEAD`
    if test -n "$(git rev-list origin ^HEAD)"
        # TODO address current branch vs its tracked? or is that implicit in this already?
        #    TLDR read up on git rev-list args
        log_ --red --bold "Upstream has new commits, pull if needed\n\n"
        exit 1
    end

    trash "$llama_dir/build"

    build_llama_cpp
end

function build_llama_cpp

    # warn user if any upstream commits, but don't stop build
    # b/c I might not want to build latest version!

    # if not git pull --rebase
    #     echo pull failed, aborting...
    #     return 1
    # end

    echo BUILDING
    # trash build ? add step
    # LLAMA_CURL=on allows downloading models
    if $IS_MACOS
        # FYI metal is enabled by default on macOS
        #   https://github.com/ggml-org/llama.cpp/blob/3eac2093/docs/build.md#L111
        cmake -B build -DLLAMA_CURL=on
    else
        if not test -f /etc/arch-release
            echo "Warning: /etc/arch-release not found – this system does not appear to be Arch Linux."
            exit 1
        end

        # just started to get failures today on build21 and build13... both had upgraded packages so maybe smth changed, i.e. using g++14 (is that newly released in arch repos?)
        #    type name is not   allowed
        # I found a similar issue on GH... guy said he fixed with setting env var vor NVCC_CCBIN... I did the same, albeit in my case g++-14, his case was g++-13
        #   and now the subsequent cmake to create build config works again!
        # https://github.com/ggml-org/llama.cpp/issues/10849
        # export NVCC_CCBIN='/usr/bin/g++-14'
        # https://github.com/ggml-org/llama.cpp/blob/3eac2093/docs/build.md#L148

        cmake -B build \
            -DGGML_CUDA=ON \
            -DLLAMA_CURL=on \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_CUDA_COMPILER=/opt/cuda/bin/nvcc \
            -DCMAKE_CUDA_HOST_COMPILER=/usr/bin/g++-15 \
            -DCMAKE_C_COMPILER=/usr/bin/gcc-15 \
            -DCMAKE_CXX_COMPILER=/usr/bin/g++-15

    end

    # PRN enable cuda if present on machine or based on machine name
    cmake --build build --config Release -- -j (nproc)

end

# * test inference infra

#  simple convenience funcs so I don't have to hunt down something special
function test_vllm_v1_completions_streaming
    echo '{
      "prompt": "Please show me the tower of hanoi in lua",
      "max_tokens": 200,
      "temperature": 0.0,
      "stream": true
    }' | http localhost:8000/v1/completions
end
function test_vllm_v1_completions
    echo '{
      "prompt": "Please show me the tower of hanoi in lua",
      "max_tokens": 200,
      "temperature": 0.0
    }' | http localhost:8000/v1/completions
end
function test_vllm_v1_completions_raw_text
    # if want a crude check of validity of generated text
    test_vllm_v1_completions | jq .choices[0].text -r
end

if command -q wscat
    abbr wscatc 'wscat --connect -L --slash --show-ping-pong ws://localhost:8000'
    abbr wscatl 'wscat --listen 8000' # run an echo server locally
    #  FYI --show-ping-pong ONLY applies when using -c/--connect (the client)
    abbr wscat_echo_org 'wscat --connect -L --slash --show-ping-pong ws://echo.websocket.org'
end

# * uname
abbr una "uname -a"

if command -q hs
    # hammerspoon

    # hs command usage:
    # hs -c foo -c bar # run foo => then bar
    # hs [-i]  # REPL
    # echo script | hs # run script

    # * interactive REPL mode:
    # -i is default on, so don't need to pass it
    # let this annoy me as a reminder that it exists (type hs<space> expands to hs -C)
    abbr hs "hs -C" # interactive, is default mode
    abbr hs_interactive "hs -C" # mostly a reminder that interactive mode exists!
    abbr hsq "hs -q"
    #
    # REPL + mirroring?
    # mirroring hs cmd/repl => hs console
    abbr hs_clone_from_console "hs -C"
    # mirroring from console => hs cmd/repl
    abbr hs_clone_to_console "hs -P"
    # FYI -C/-P won't work with my hack to suppress the hard coded print("-- Loading extension: "..key)
    #   which is baked into hammerspoon's code:
    #     https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/_coresetup/_coresetup.lua#L456
    #   so my override (which temporarily overrides print, probably means -C/-P patches my print override
    #   so when I put the original print back then the override is gone!

    # running commands
    abbr hsc "hs -c" # run a command
    abbr hs_open_console "hs -c 'hs.openConsole()'"
    abbr hs_reload "hs -c 'hs.openConsole(); hs.reload(); hs.console.clearConsole()'"
    abbr hs_clear_console "hs -c 'hs.console.clearConsole()'"
    abbr hscq "hs -c -q" # quiet mode (only errors and final result)

end

if command -q ctags
    abbr ct ctags
    abbr ctags_stdout_only_lua "ctags --languages=lua -f -"
    abbr --set-cursor ctl ctags --list-%
    abbr ctle ctags --list-excludes
    abbr ctll ctags --list-languages
    abbr ctlf ctags --list-fields
    abbr ctlx ctags --list-extras
    abbr ctags_stdout ctags -f -
    # helpers to review what was swept up (or not)
    abbr ctags_list_not_files "cat tags  | sort | uniq | rg_grep --invert-match '\.(zsh|lua|py|rs|c|md|json|vim|plist|js|ps1)' | bat -l csv"

end

# # lets see how I feel about awk being auto '' quoted... I can change later if this upsets me
# #   i.e. if I find myself often wanting to set args -F ... then this might be annoying
# # abbr --set-cursor awk "awk '/%/ { print }'"
# #
# # abbr awk4 "awk '{print $4}'"
# abbr --add _awkd --regex 'awk\d+' --function _abbr_expand_awk
# function _abbr_expand_awk
#     string replace --regex "(\d+)" " '{print \\\$\$1}'" $argv[1]
# end
#
# # PRN add back if actually useful... for now don't need a-zA-Z for the separator!
# # # abbr awk4_ where _ is any character you want
# # abbr --add _awkd_char --regex 'awk\d+([a-zA-Z])' --function _abbr_expand_awk_char
# # function _abbr_expand_awk_char
# #     string replace --regex "(\d+)([a-zA-Z])" " \-F\$2 '{print \\\$\$1}'" $argv[1]
# # end
#
# # awk4t
# abbr --add _awk_tab --regex 'awk\d+t' --function _abbr_expand_awk_tab
# function _abbr_expand_awk_tab
#     string replace --regex "(\d+)t" " \-F'\t' '{print \\\$\$1}'" $argv[1]
# end
#
# # awk4,
# abbr --add _awk_comma --regex 'awk\d+,' --function _abbr_expand_awk_comma
# function _abbr_expand_awk_comma
#     string replace --regex "(\d+)," " \-F, '{print \\\$\$1}'" $argv[1]
# end
#
# # awk4p (as in pipe | delimiter)
# #  cannot type | in an abbr b/c its a command delimiter
# abbr --add _awk_pipe --regex 'awk\d+p' --function _abbr_expand_awk_pipe
# function _abbr_expand_awk_pipe
#     string replace --regex "(\d+)p" " \-F'\|' '{print \\\$\$1}'" $argv[1]
# end

# * comm(on) command
#  honestly this makes me wanna write some of my own commands that aren't abbreviated for 32KB tech from 70 years ago
#  fish like fashion: `lines intersect` `lines union` `lines left-only` `lines right-only`
#     maybe even `lines diff` should be here too? maybe not
# *** openai completions helpers

# not just psse b/c I can't get tab completion of --position=anywhere abbreviations
#  strip until first { .. that way any prefix (data: and/or log messages) are stripped at front of line
#    that means I can double click a line in llama-server logs and copy all of it and jq just works!
set --local sse_jq 'string replace --regex "[^{]*" "" | jq'
# pipe alone (not from clippy)
abbr --position=anywhere -- psse "| $sse_jq"
abbr --position=anywhere -- pssec "| $sse_jq --compact-output"
abbr --position=anywhere -- pdata "| rg_grep -v ':data' | $sse_jq" # filter to just data: records in HTTP SSE trace (i.e. skip lines w/ `event: message`)
#
# * pbcopy
#   until I habituate these, use _copy_ expanded as reminder (shorten later if use this all the time)
abbr -- pb_copy_sse "pbpaste | $sse_jq | pbcopy" # * idempotent (keep it that way)
#
# * pb - paste then pipe
abbr -- pbsse "pbpaste | $sse_jq"
abbr -- pbssec "pbpaste | $sse_jq --compact-output"
# grab __verbose.prompt (llama-server uses this)
abbr -- pbsse_verbose_prompt "pbpaste | $sse_jq '.__verbose.prompt' -r"
# TODO I really need to write my own script (python?) and have this do detection on the prompt value and just auto suggest adding treesitter on the end
#    and add support for other formats and coloring them
abbr -- pbsse_verbose_prompt_harmony "pbpaste | $sse_jq '.__verbose.prompt' -r | tree-sitter highlight --scope source.harmony"
abbr -- pbsse_verbose_content "pbpaste | $sse_jq '.__verbose.content' -r" # this is the RAW RESPONSE from the model
abbr -- pbsse_verbose_raw_response "pbpaste | $sse_jq '.__verbose.content' -r" # this is the RAW RESPONSE from the model
abbr -- pbsse1 "pbpaste | $sse_jq > input-messages.json"
abbr -- pbsse2 "pbpaste | $sse_jq > input-rendered-prompt.json"
abbr -- pbsse3 "pbpaste | $sse_jq > output-parsed-message.json"
abbr -- pbssetrace 'view_trace (pbpaste | string replace --regex "[^{]*" "" | psub)'

#
# * pbsse4 (raw prompt)
# FYI sse4 is not an sse but the naming convention helps me quickly remember each of these! (first 3 are SSEs)
abbr -- pbsse4 "pbpaste | string replace --regex '^\w\w\w \d\d \d\d:\d\d:\d\d \w+ llama-server\[\d+\]: ' '' | string replace 'Parsing input with format GPT-OSS: ' '' > output-raw.harmony"
# strip this from all lines:
#   Dec 09 18:11:03 build21 llama-server[3344]:
# then first line also has:
#   Parsing input with format GPT-OSS:
#
# FYI I assume line breaks in logs are from literal line breaks in the response that s/b preserved
#  TODO setup to work with other prompt types... not just GPT-OSS/harmony... i.e. Qwen3
#  TODO and setup to rename file based on prompt format (if applicable?) .. at least not call it .harmony :)

# * llama-server endpoints
# reminder abbr:
abbr llama_server_current_chat_template "curl paxy:8013/props | jq .chat_template --raw-output"

# ? --join-output

# * jq command

# * expand short options => corresponding long option
abbr --command jq -- -S --sort-keys
abbr --command jq -- -C --color-output
abbr --command jq -- -c --compact-output
abbr --command jq -- -r --raw-output
abbr --command jq -- -j --join-output # one use case: don't end w/ \n
#
abbr jqk "jq keys"
#
# helpers for jq patterns I never remember (with completions of non-command abbrs, these are immensly more useful)
abbr --command jq -- sort_keys 'jq --sort-keys' # reminder abbr with tab completing anywhere abbrs fix
abbr --command jq -- not_null "| select(.)" # or this works: `"| select(. != null)"` works
# TODO expand this list over time, try to capture the key ones you struggle to remember
# FYI one unfortunate part is that inside the quoted jq expression, you cannot expand abbrs b/c the entire quoted part is the token to expand
#   but I can arrow out of the quoting to get some help (delete latter ' to go back into non quoted territory and add back quote once done

# * yq (normally yq intended => jq but can output yaml too)
abbr yqy "yq --yaml-output"
# short to long options
abbr --command yq -- -y --yaml-output
abbr --command yq -- -c --compact-output
abbr --command yq -- -r --raw-output

# * date
if command -q claude
    # run claude code w/ local model
    abbr clm 'ANTHROPIC_BASE_URL="http://ask.lan:8012" claude --model Qwen/Qwen3-Coder-Next-GGUF:Q8_0' # for now just leave full model name as a reminder for one model
    abbr clr 'claude --resume'
    abbr cld 'claude --dangerously-skip-permissions'
end

# *** nix
abbr --command nix -- -h --help
abbr -- nixh "nix --help"
abbr -- nixpls "nix profile list"
