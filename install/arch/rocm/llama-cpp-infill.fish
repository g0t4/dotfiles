
./build/bin/llama-server -h




# TODO other models... what about serve multiple models too?
# -hf ggml-org/Qwen2.5-Coder-7B-Q8_0-GGUF \

# not just localhost:
./build/bin/llama-server \
    -hf ggml-org/Qwen2.5-Coder-3B-Q8_0-GGUF \
    --port 8012 -ngl 99 -fa -ub 1024 -b 1024 \
    --ctx-size 0 --cache-reuse 256 --host 0.0.0.0
# can I pass a models directory and serve all of them?


# FYI api endpoint regisrations:
#    https://github.com/ggerganov/llama.cpp/blob/master/examples/server/server.cpp#L4355

# TODO test /infill
#   --spm-infill
--spm-infill use Suffix/Prefix/Middle pattern for infill (instead of Prefix/Suffix/Middle) as some models prefer this. (default: disabled)


curl http://ollama:8012/v1/models
# id => "/home/wes/.cache/llama.cpp/ggml-org_Qwen2.5-Coder-7B-Q8_0-GGUF_qwen2.5-coder-7b-q8_0.gguf"


# src: https://github.com/ggerganov/llama.cpp/blob/master/examples/server/server.cpp#L3942
# TODO use model alias to avoid filename path
curl -X POST http://ollama:8012/infill \
    -d '{
   "raw":true,
   "num_predict":40,
   "model": "/home/wes/.cache/llama.cpp/ggml-org_Qwen2.5-Coder-7B-Q8_0-GGUF_qwen2.5-coder-7b-q8_0.gguf",
   "stream":true,
   "input_prefix": "a = 1 + 2",
   "input_suffix": "c = a + b"
}'
# prompt is optional - TODO try it
#"prompt":"",

# IIAC this is for context or?
# todo input_extra": [{"filename": "", "text": "" }]
