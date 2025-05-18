
./build/bin/llama-server -h

# btw find GGUF existing models, i.e. qwen:
#  https://huggingface.co/Qwen?search_models=GGUF
#   open a "repo" and go to its files tab,  find GGUF files to download
#   use arrow that points down in middle to copy link and wget:
wget "https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q8_0.gguf"
#   mod this to get variants
#     in case of qwen, can swap 7B and 7b for 3B 3b.. and it works
wget "https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q8_0.gguf"
#
# FYI for now store here:
ls ~/repos/github/ggml-org/llama.cpp/models/qwen2.5*

# TODO other models... what about serve multiple models too?
# -hf ggml-org/Qwen2.5-Coder-7B-Q8_0-GGUF \

# not just localhost:
./build/bin/llama-server \
    -hf ggml-org/Qwen2.5-Coder-3B-Q8_0-GGUF \
    --port 8012 -ngl 99 -fa -ub 1024 -b 1024 \
    --ctx-size 0 --cache-reuse 256 --host 0.0.0.0 \
    --log-colors --alias qwen-infill -v

# can I pass a models directory and serve all of them?


# FYI api endpoint regisrations:
#    https://github.com/ggml-org/llama.cpp/blob/master/examples/server/server.cpp#L4355

# TODO test /infill
#   --spm-infill
--spm-infill use Suffix/Prefix/Middle pattern for infill (instead of Prefix/Suffix/Middle) as some models prefer this. (default: disabled)


curl http://ollama:8012/v1/models
# id => "/home/wes/.cache/llama.cpp/ggml-org_Qwen2.5-Coder-7B-Q8_0-GGUF_qwen2.5-coder-7b-q8_0.gguf"


# src: https://github.com/ggml-org/llama.cpp/blob/master/examples/server/server.cpp#L3942
# TODO use model alias to avoid filename path
curl -X POST http://ollama:8012/infill \
    -d '{
   "raw":true,
   "num_predict":40,
   "stream":true,
   "input_prefix": "a = 1 + 2",
   "input_suffix": "c = a + b"
}'
# "model" seems optional... b/c IIUC only one ever loaded at a time in llama-server
# "model": "qwen-infill",
# "model": "~/.cache/llama.cpp/ggml-org_Qwen2.5-Coder-3B-Q8_0-GGUF_qwen2.5-coder-3b-q8_0.gguf",
# "model": "/home/wes/.cache/llama.cpp/ggml-org_Qwen2.5-Coder-7B-Q8_0-GGUF_qwen2.5-coder-7b-q8_0.gguf",

# *** matching prompt after FIM template:
# -v == verbose (debug) logs [shows prompt after FIM'in it]
# BTW launching slot:
# {"id":0,"id_task":0,"n_ctx":32768,"speculative":false,"is_processing":false,"non_causal":false,"params":{"n_predict":-1,"seed":4294967295,"temperature":0.800000011920929,"dynatemp_range":0.0,"dynatemp_exponent":1.0,"top_k":40,"top_p":0.949999988079071,"min_p":0.05000000074505806,"xtc_probability":0.0,"xtc_threshold":0.10000000149011612,"typical_p":1.0,"repeat_last_n":64,"repeat_penalty":1.0,"presence_penalty":0.0,"frequency_penalty":0.0,"dry_multiplier":0.0,"dry_base":1.75,"dry_allowed_length":2,"dry_penalty_last_n":32768,"dry_sequence_breakers":["\n",":","\"","*"],"mirostat":0,"mirostat_tau":5.0,"mirostat_eta":0.10000000149011612,"stop":[],"max_tokens":-1,"n_keep":0,"n_discard":0,"ignore_eos":false,"stream":true,"logit_bias":[],"n_probs":0,"min_keep":0,"grammar":"","grammar_trigger_tokens":[],"samplers":["penalties","dry","top_k","typ_p","top_p","min_p","xtc","temperature"],"speculative.n_max":16,"speculative.n_min":5,"speculative.p_min":0.8999999761581421,"timings_per_token":false,"post_sampling_probs":false,"lora":[]},"prompt":"<|repo_name|>myproject\n<|file_sep|>filename\n<|fim_prefix|>a = 1 + 2<|fim_suffix|>c = a + b<|fim_middle|>","next_token":{"has_next_token":true,"has_new_line":false,"n_remain":-1,"n_decoded":0,"stopping_word":""}}
#      "prompt": "<|repo_name|>myproject\n<|file_sep|>filename\n<|fim_prefix|>a = 1 + 2<|fim_suffix|>c = a + b<|fim_middle|>",

#   format_infill:  https://github.com/ggml-org/llama.cpp/blob/master/examples/server/utils.hpp#L252


# prompt is optional - TODO try it
#"prompt":"",
"~/.cache/llama.cpp/ggml-org_Qwen2.5-Coder-3B-Q8_0-GGUF_qwen2.5-coder-3b-q8_0.gguf"
# IIAC this is for context or?
# todo input_extra": [{"filename": "", "text": "" }]
#    ok these are separate file chunks ... filename + text is contents... using Repo level FIM (so these become context before the FIM at the end...

# ok this is what they have in comments:
#
#    // use FIM repo-level pattern:
#    // ref: https://arxiv.org/pdf/2409.12186
#    //
#    // [FIM_REP]myproject
#    // [FIM_SEP]filename0
#    // extra chunk 0
#    // [FIM_SEP]filename1
#    // extra chunk 1
#    // ...
#    // [FIM_SEP]filename
#    // [FIM_PRE]prefix[FIM_SUF]suffix[FIM_MID]prompt
#    //
#
#    hrm... did I miss the paper saying they always used FIM_SEP before the PSM? I thought repo-level vs FIM were alternatives, not compliments? or do they just end up working as both?
#    myproject name - not yet an input, but marked to be added... (for the repo name)
#    also `filename` is hardcoded for the last FIM_SEP]filename  :( with a TODO on it... why!?
