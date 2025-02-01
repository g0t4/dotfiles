# confirm device:
rocminfo | grep gfx | head -1 | awk '{print $2}'





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

