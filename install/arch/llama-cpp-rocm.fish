
cd ~/repos/github/ggerganov/llama.cpp

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
# https://github.com/ggerganov/llama.cpp/blob/master/docs/build.md#hip
HIPCXX="$(hipconfig -l)/clang" HIP_PATH="$(hipconfig -R)" \
    cmake -S . -B build -DGGML_HIP=ON -DAMDGPU_TARGETS=gfx1030 -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_CURL=ON \
    && cmake --build build --config Release -- -j 16

# FYI LLAMA_CURL => otherwise cannot download models (i.e. from huggingface)
