

# *** building llama.cpp

cd ~/repos/github/ggml-org/llama.cpp

rm -rf build # get rid of full dir first

# add hipconfig to path
set PATH /opt/rocm/bin $PATH

# TODO suss out which of these I need...
# FYI [LD]_LIBRARY_PATH fixes the last error so one or both of those are needed
#ld.lld: error: unable to find library -lamdhip64
#clang: error: linker command failed with exit code 1 (use -v to see invocation)
set LIBRARY_PATH /opt/rocm/lib $LIBRARY_PATH
export LIBRARY_PATH
set LD_LIBRARY_PATH /opt/rocm/lib $LD_LIBRARY_PATH
export LD_LIBRARY_PATH
set CPATH /opt/rocm/include $CPATH
export CPATH
export LDFLAGS="-L/opt/rocm/lib"


# docs for llama.cpp w/ hip(blas)
# https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#hip
HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
    cmake -S . -B build -DGGML_HIP=ON -DAMDGPU_TARGETS=gfx1030 -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_CURL=ON \
    && cmake --build build --config Release -- -j 16

# FYI LLAMA_CURL => otherwise cannot download models (i.e. from huggingface)




# *** testing it
# test model:
# https://huggingface.co/Qwen/Qwen2.5-Coder-0.5B-Instruct-GGUF/tree/main # pick one, i.e.:
wget https://huggingface.co/Qwen/Qwen2.5-Coder-0.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-0.5b-instruct-q4_k_m.gguf
wget https://huggingface.co/Qwen/Qwen2.5-Coder-3B-Instruct-GGUF/resolve/main/qwen2.5-coder-3b-instruct-q4_k_m.gguf
wget https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q4_k_m.gguf
wget https://huggingface.co/Qwen/Qwen2.5-Coder-14B-Instruct-GGUF/resolve/main/qwen2.5-coder-14b-instruct-q4_k_m.gguf
wget https://huggingface.co/Qwen/Qwen2.5-Coder-32B-Instruct-GGUF/resolve/main/qwen2.5-coder-32b-instruct-q4_k_m.gguf

# what does this model do?!
wget https://huggingface.co/DuckyBlender/racist-phi3-GGUF/resolve/main/racist-phi3-q4_K_M.gguf

./build/bin/llama-cli -m models/qwen2.5-coder-0.5b-instruct-q4_k_m.gguf -p "fuck you"
#
# benchmarks finally, what I set out to get this AM and got side tracked 20 times over :)
./build/bin/llama-bench -m models/qwen2.5-coder-* # TODO run all of them and take Pax out to potty






