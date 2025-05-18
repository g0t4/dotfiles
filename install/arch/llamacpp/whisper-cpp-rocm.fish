cd ~/repos/github/ggml-org/whisper.cpp

rm -rf build # get rid of full dir first
#  git status --ignored   # review previous build artifacts

# activate hipcc "env"
set PATH /opt/rocm/bin $PATH # hipconfig
# FYI I do not know why/if all this is needed to build... but it does work when I use the following
#    TODO test which of these is actually needed, dig into each?
# -- fixes missing -lamdhip64 error
#
# # tested w/o these and it works fine:
#set LIBRARY_PATH /opt/rocm/lib $LIBRARY_PATH
#export LIBRARY_PATH
#set LD_LIBRARY_PATH /opt/rocm/lib $LD_LIBRARY_PATH
#export LD_LIBRARY_PATH
#
set CPATH /opt/rocm/include $CPATH
export CPATH
#export LDFLAGS="-L/opt/rocm/lib" # also working w/o this

cmake -B build -DCMAKE_C_COMPILER="$(hipconfig -l)/clang" \
    -DCMAKE_CXX_COMPILER="$(hipconfig -l)/clang++" \
    -DGGML_HIP=ON \
    -DCMAKE_HIP_COMPILER_ROCM_ROOT=/opt/rocm

cmake --build build -j --config Release


# test it:
./build/bin/whisper-cli -f samples/jfk.wav
# ensure in output:
#    whisper_backend_init_gpu: using ROCm0 backend
