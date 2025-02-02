
./build/bin/llama-server -h

# not just localhost:
./build/bin/llama-server \
    -hf ggml-org/Qwen2.5-Coder-3B-Q8_0-GGUF \
    --port 8012 -ngl 99 -fa -ub 1024 -b 1024 \
    --ctx-size 0 --cache-reuse 256 --host 0.0.0.0


# FYI api endpoint regisrations:
#    https://github.com/ggerganov/llama.cpp/blob/master/examples/server/server.cpp#L4355

# TODO test /infill

