# AMD GPU support
sudo pacman --needed --noconfirm -S \
    rocm-hip-sdk rocminfo rocm-hip-runtime hipblas

# not in path (which is fine, dont add to path, can just mod path for using hipcc, etc)
/opt/rocm/bin/rocminfo


# whisper.cpp uses openblas (do not install system wide, conflicts with hipblas used by ggml above, ugh)
# wait are cblas/openblas/hipblas interchangeable? or not sure hip/cblas conflict actually they seem to work together
sudo pacman --noconfirm -S openblas

# TODO or opencl?

# see examples repo for test cases of hipblas compiler hipcc
