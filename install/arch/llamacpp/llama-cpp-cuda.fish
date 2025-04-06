cd ~/repos/github/ggerganov/llama.cpp
rm -rf build # get rid of full dir first

# steps to use w/ nvidia 5090
# docs for CUDA:
#   https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#cuda
#  btw compute capability lookup:
#    https://docs.nvidia.com/cuda/cuda-c-programming-guide/index.html#compute-capabilities

cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release -- -j (nproc)

# RUNTIME:
#  unified memory:
#    TODO try using unified to fallback to SYSTEM RAM (should help w/ MoE not to load off disk)
#    GGML_CUDA_ENABLE_UNIFIED_MEMORY=1
#    https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#unified-memory
#  perf tuning options:
#    https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md#performance-tuning
#
