#
# *** llama.cpp, first get it compiling w/o hipblas
cmake -B build
cmake --build build --config Release -j 12

# *** ok nvm skip whisper for now, I can come back to it... go for the gold w/ llama.cpp
# + HIP:   https://github.com/ggerganov/llama.cpp/blob/master/docs/build.md#hip
#   hipblas is needed for amd gpus (offidially listed):   https://github.com/ggerganov/llama.cpp/blob/master/docs/build.md#hip
#
# activate hipcc "env"
set PATH /opt/rocm/bin $PATH
# -- fixes missing -lamdhip64 error
set LIBRARY_PATH /opt/rocm/lib $LIBRARY_PATH
export LIBRARY_PATH
set LD_LIBRARY_PATH /opt/rocm/lib $LD_LIBRARY_PATH
export LD_LIBRARY_PATH
set CPATH /opt/rocm/include $CPATH
export CPATH
export LDFLAGS="-L/opt/rocm/lib"
#
# confirm device:
rocminfo | grep gfx | head -1 | awk '{print $2}'
#
HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
    cmake -S . -B build -DGGML_HIP=ON -DAMDGPU_TARGETS=gfx1030 -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build --config Release -- -j 16
# WORKS!
# not compiled w/ libcurl ... so I have to download models, that's fine
#
# test model:
# https://huggingface.co/Qwen/Qwen2.5-Coder-0.5B-Instruct-GGUF/tree/main # pick one, i.e.:
wget https://huggingface.co/Qwen/Qwen2.5-Coder-0.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-0.5b-instruct-q4_k_m.gguf
./build/bin/llama-cli -m models/qwen2.5-coder-0.5b-instruct-q4_k_m.gguf -p "fuck you"
#
# benchmarks finally, what I set out to get this AM and got side tracked 20 times over :)
./build/bin/llama-bench -m models/qwen2.5-coder-0.5b-instruct-q4_k_m.gguf







# *** ggml builds:
# NOTES FROM HIPBLAS+ggml test builds (did not get working YET:)
#
# AMD GPU support
sudo pacman --needed --noconfirm -S \
    rocm-hip-sdk rocminfo rocm-hip-runtime hipblas

# not in path (which is fine, dont add to path, can just mod path for using hipcc, etc)
/opt/rocm/bin/rocminfo
# see examples repo for test cases of hipblas compiler hipcc


# *** whisper.cpp
#   can I use hipblas w/ whisper? ... repo has many refs to AMD/ROCM... must be possible via hipblas IIAC? or is whipser mostly CPU insructrs... and thus OpenBlas?
#
# whisper docs mention openblas
# whisper.cpp uses openblas (do not install system wide, conflicts with hipblas used by ggml above, ugh)
# wait are cblas/openblas/hipblas interchangeable? or not sure hip/cblas conflict actually they seem to work together
sudo pacman --noconfirm -S openblas

