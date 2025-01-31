# AMD GPU support
sudo pacman --needed --noconfirm -S \
    rocm-hip-sdk rocminfo rocm-hip-runtime hipblas

# not in path (which is fine, dont add to path, can just mod path for using hipcc, etc)
/opt/rocm/bin/rocminfo

# see examples repo for test cases of hipblas compiler hipcc
