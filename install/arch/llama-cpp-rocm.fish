
cd ~/repos/github/ggerganov/llama.cpp

rm -rf build # get rid of full dir first

# add hipconfig to path
set PATH /opt/rocm/bin $PATH

set CPATH /opt/rocm/include $CPATH
export CPATH

# docs for llama.cpp w/ hip(blas)
# https://github.com/ggerganov/llama.cpp/blob/master/docs/build.md#hip

HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
    cmake -S . -B build -DGGML_HIP=ON -DAMDGPU_TARGETS=gfx1030 -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build --config Release -- -j 16


